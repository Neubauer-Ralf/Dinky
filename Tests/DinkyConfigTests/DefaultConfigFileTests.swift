import Foundation
import Testing
@testable import DinkyConfig

struct DefaultConfigFileTests {
    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "dinky-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func `A missing config is written with the default`() throws {
        let dir = try directory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "dinky/dinky.toml")
        Config.writeDefaultIfMissing(at: url)
        #expect(try Config.load(from: url) == Config.default)
    }

    @Test func `An existing config is left alone`() throws {
        let dir = try directory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "dinky.toml")
        try "workspaces = 3\n".write(to: url, atomically: false, encoding: .utf8)
        Config.writeDefaultIfMissing(at: url)
        #expect(try String(contentsOf: url, encoding: .utf8) == "workspaces = 3\n")
    }

    /// A config symlinked from a dotfiles checkout that is not there yet must not be replaced by a file.
    @Test func `A symlink to a missing config is left alone`() throws {
        let dir = try directory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "dinky.toml"), target = dir.appending(path: "dotfiles/dinky.toml").path
        try FileManager.default.createSymbolicLink(atPath: url.path, withDestinationPath: target)
        Config.writeDefaultIfMissing(at: url)
        #expect(try FileManager.default.destinationOfSymbolicLink(atPath: url.path) == target)
        #expect(!FileManager.default.fileExists(atPath: target))
    }
}
