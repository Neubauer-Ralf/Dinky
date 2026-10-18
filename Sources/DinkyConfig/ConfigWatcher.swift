import Foundation

/// Watches a config file and reloads it when it changes, debounced. Each reload calls `onChange`
/// on the main queue with the new config or the error; the caller keeps the previous config on error.
///
/// Editors often save by writing a new file and renaming it over the old one, which leaves the
/// watched descriptor pointing at a deleted file. So after every change the file is reopened,
/// and while it is missing it is polled until it comes back.
///
/// The file descriptor follows a symlink to its target, so replacing the link itself (`ln -sf`, or a file
/// renamed over it) changes nothing it sees. The link's directory is watched too, and a change there reloads
/// when the config's own entry is a different one than at the last load.
public final class ConfigWatcher {
    private let url: URL
    private let onChange: (Result<Config, ConfigError>) -> Void
    private let queue = DispatchQueue(label: "dinky.config-watcher")
    private var source: DispatchSourceFileSystemObject?
    private var directory: DispatchSourceFileSystemObject?
    /// The config path's own entry (not a symlink's target) when it was last opened; nil while missing.
    private var entry: Entry?
    private var pending: DispatchWorkItem?
    /// Set by `stop()`, so the poll for a missing file, which can't be cancelled, does not start watching again.
    private var stopped = false

    public init(url: URL, onChange: @escaping (Result<Config, ConfigError>) -> Void) {
        self.url = url
        self.onChange = onChange
        queue.sync { watch() }
    }

    deinit {
        source?.cancel()
        directory?.cancel()
        pending?.cancel()
    }

    public func stop() {
        queue.sync {
            stopped = true
            source?.cancel()
            source = nil
            directory?.cancel()
            directory = nil
            pending?.cancel()
        }
    }

    private func watch() {
        source?.cancel()
        source = nil
        entry = Entry(url)
        if directory == nil { watchDirectory() }
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            queue.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.reopenIfMissing() }
            return
        }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend, .delete, .rename], queue: queue
        )
        source.setEventHandler { [weak self] in self?.changed() }
        source.setCancelHandler { close(fd) }
        source.resume()
        self.source = source
    }

    private func watchDirectory() {
        let fd = open(url.deletingLastPathComponent().path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: queue)
        // Any file coming or going in the directory lands here; only a new entry at the config path counts. It is
        // noted at once, so the neighbours' events that follow don't push the debounced reload back again and again.
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let now = Entry(url)
            guard now != entry else { return }
            entry = now
            changed()
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        directory = source
    }

    private func reopenIfMissing() {
        guard !stopped, source == nil else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            changed()
        } else {
            watch()
        }
    }

    private func changed() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reload() }
        pending = work
        queue.asyncAfter(deadline: .now() + 0.1, execute: work)
    }

    private func reload() {
        watch()
        let result = Result { () throws(ConfigError) in try Config.load(from: url) }
        DispatchQueue.main.async { [onChange] in onChange(result) }
    }
}

/// A directory entry by device and inode, read without following a symlink.
private struct Entry: Equatable {
    let device: dev_t
    let inode: ino_t

    init?(_ url: URL) {
        var info = stat()
        guard lstat(url.path, &info) == 0 else { return nil }
        device = info.st_dev
        inode = info.st_ino
    }
}
