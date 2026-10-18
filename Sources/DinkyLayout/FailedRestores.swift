import CoreGraphics

// Where a failed restore left each window it could not put back. Disabling or quitting tries those windows again
// later, but while dinky is off the user arranges windows by hand, and a window moved since is theirs: a retry
// skips it, and when tiling resumes it is journaled again from where it is now. A window still where the failed
// attempt left it keeps its original frame, so one whose display was unplugged still goes home later.

/// A window's frame and Space, as read back from the window server.
public struct WindowPosition: Equatable, Sendable {
    public let frame: CGRect
    public let spaceID: UInt64

    public init(frame: CGRect, spaceID: UInt64) {
        self.frame = frame
        self.spaceID = spaceID
    }
}

public struct FailedRestores: Equatable, Sendable {
    private var leftAt: [WindowID: WindowPosition] = [:]

    public init() {}

    /// Remembers where a failed restore left `id`, replacing what an earlier attempt left.
    public mutating func remember(_ id: WindowID, at position: WindowPosition) {
        leftAt[id] = position
    }

    /// Whether `id` failed to restore and has been moved since, by frame or by Space. False for a window no failed
    /// restore left behind.
    public func movedByHand(_ id: WindowID, now: WindowPosition) -> Bool {
        guard let position = leftAt[id] else { return false }
        return position != now
    }

    /// Keeps only the windows in `ids`: the rest were restored, closed or given up on.
    public mutating func keep(_ ids: Set<WindowID>) {
        leftAt = leftAt.filter { ids.contains($0.key) }
    }

    /// Forgets every window, once tiling resumes and dinky owns the frames again.
    public mutating func clear() {
        leftAt = [:]
    }

    public var ids: Set<WindowID> { Set(leftAt.keys) }
}
