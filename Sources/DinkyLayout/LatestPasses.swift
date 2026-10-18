import Foundation

/// Numbers passes as they are queued and remembers the newest to include each window, so work a pass finishes
/// late, such as raising windows into its stacking order, can be skipped once a newer pass covers the same
/// windows. Passes finish out of order: one waits for its slowest app. Thread-safe.
public final class LatestPasses: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    private var newest: [WindowID: Int] = [:]

    public init() {}

    /// Starts a pass over `ids` and returns its number.
    public func begin(_ ids: [WindowID]) -> Int {
        lock.withLock {
            count += 1
            for id in ids { newest[id] = count }
            return count
        }
    }

    /// Whether no pass begun after `pass` includes any of `ids`.
    public func isLatest(_ pass: Int, for ids: [WindowID]) -> Bool {
        lock.withLock { ids.allSatisfy { (newest[$0] ?? 0) <= pass } }
    }

    /// Forgets a window that is gone, so its id, once reused, starts afresh.
    public func forget(_ id: WindowID) {
        lock.withLock { newest[id] = nil }
    }
}
