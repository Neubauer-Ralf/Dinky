// Whether the windows a display change poured off their workspaces go back once the Spaces are arranged.
// A display coming or going marks them; the next arrangement decides, and clears the mark either way. Only a
// completed arrangement while enabled returns them. One that stopped short leaves them, and so does a display
// change while disabled: dinky then leaves windows where macOS put them, and by the time it is enabled the
// user may have moved them, so where they were before the change says nothing any more.
// Pure: the app notes homes, arranges and moves the windows.

public struct DisplacedWindows: Equatable {
    public enum Outcome: Equatable {
        /// No display change since the last arrangement.
        case nothing
        /// Move the windows back to the workspaces noted before the change.
        case returnThem
        /// Leave them where they are.
        case leaveThem
    }

    /// From a display change until the next arrangement. Homes are not noted meanwhile, so they say where
    /// windows were before the change.
    public private(set) var pending = false

    public init() {}

    public mutating func displaysChanged() { pending = true }

    /// An arrangement ran, or was skipped because dinky is disabled.
    public mutating func arranged(enabled: Bool, completed: Bool) -> Outcome {
        defer { pending = false }
        guard pending else { return .nothing }
        return enabled && completed ? .returnThem : .leaveThem
    }
}
