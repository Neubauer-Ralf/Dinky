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

/// Why a restore could not put a window back, and whether a later restore may still manage it. Only a window held
/// up by something that passes is kept: an app that did not answer in time, a display or Space move that did not
/// go through. A window that answered with another frame (held by a minimum size) or could not be read back gets
/// the same answer every time, and kept journaled it would be offered as "Restore N windows" at every launch.
public enum RestoreProblem: Equatable, Sendable, CustomStringConvertible {
    case closed
    case movedByHand
    case displayGone
    case spaceGone
    case spaceMoveFailed
    case didNotArrive
    case noAnswer(seconds: Int)
    case unreadable(wanted: CGRect)
    case wrongFrame(got: CGRect, wanted: CGRect)

    /// Whether the window stays journaled for the next restore.
    public var retries: Bool {
        switch self {
        case .displayGone, .spaceMoveFailed, .didNotArrive, .noAnswer: true
        case .closed, .movedByHand, .spaceGone, .unreadable, .wrongFrame: false
        }
    }

    public var description: String {
        switch self {
        case .closed: "closed"
        case .movedByHand: "moved by hand since the last try, leaving it there"
        case .displayGone: "its display is gone"
        case .spaceGone: "its Space is gone"
        case .spaceMoveFailed: "move to its Space failed"
        case .didNotArrive: "did not arrive on its Space"
        case .noAnswer(let seconds): "no answer within \(seconds) s"
        case .unreadable(let wanted): "unreadable, wanted \(wanted)"
        case .wrongFrame(let got, let wanted): "frame \(got), wanted \(wanted)"
        }
    }
}
