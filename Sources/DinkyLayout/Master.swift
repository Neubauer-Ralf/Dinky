// The master layout, after Hyprland's: one window, the master, takes a share of the screen on one side and the
// others share the rest in a stack beside it. The first window is the master and fills the screen alone; the
// second opens the stack and later ones join its bottom. When the master closes, the top of the stack takes its
// place; when the stack empties, the master fills the screen again.
//
// The tree keeps one shape: a row holding the master window and the stack, a container of windows only. The stack
// runs top to bottom as tiles or an accordion, and `layout` commands change it whichever window is focused. A
// command that changes the shape, such as join-with, leaves the master layout the way a tree command leaves a
// fixed template: windows then open beside the focused one until `flatten-workspace-tree` rebuilds the shape.

/// The side of the screen the master window takes.
public enum MasterOrientation: Equatable, Sendable {
    case left, right
}

extension Workspace {
    public var isMaster: Bool { if case .master = algorithm { true } else { false } }

    /// The index of the master in the root row: the stack goes on the other side.
    private var masterIndex: Int {
        guard case .master(.right) = algorithm, root.children.count == 2 else { return 0 }
        return 1
    }

    /// The path of the stack, nil while the master is alone or the workspace is empty.
    var stackPath: [Int]? { root.children.count == 2 ? [1 - masterIndex] : nil }

    /// Whether the tree has the master layout's shape: nothing, a lone window, or a window and a stack of windows
    /// side by side, the window on the configured side.
    var isMasterTree: Bool {
        guard isMaster, root.orientation == .horizontal, root.mode == .tiles, root.children.count <= 2 else { return false }
        guard root.children.count == 2 else { return root.children.allSatisfy { if case .window = $0 { true } else { false } } }
        guard case .window = root.children[masterIndex], case .container(let stack) = root.children[1 - masterIndex] else { return false }
        return !stack.children.isEmpty && stack.children.allSatisfy { if case .window = $0 { true } else { false } }
    }

    /// The master window, nil if the workspace is empty or not in the master shape.
    var masterWindow: WindowID? {
        guard isMasterTree, !root.children.isEmpty, case .window(let id) = root.children[masterIndex] else { return nil }
        return id
    }

    /// The master's share and the stack's, in the root row's order.
    private var masterRatios: [Double] {
        masterIndex == 0 ? [masterSize, 1 - masterSize] : [1 - masterSize, masterSize]
    }

    /// Windows in master order: the master, then the stack from the top.
    var masterOrder: [WindowID] {
        guard let master = masterWindow else { return windows }
        return [master] + (stackPath.map { root.node(at: $0).windows } ?? [])
    }

    /// Make the first window the master, open the stack with the second and add later ones to its bottom.
    /// False if the tree has left the master shape.
    mutating func insertIntoMaster(_ id: WindowID) -> Bool {
        guard isMasterTree else { return false }
        switch root.children.count {
        case 0:
            root.insert(.window(id), at: 0)
        case 1:
            let stack = Container(stackOrientation, stackMode, [.window(id)])
            guard case .master(let side) = algorithm else { return false }
            root.insert(.container(stack), at: side == .left ? 1 : 0)
            root.setRatios(masterRatios)
        default:
            root.modify(at: stackPath!) { $0.insert(.window(id), at: $0.children.count) }
        }
        return true
    }

    /// Remove the window at `path` from a master-shaped tree: the top of the stack replaces a closing master, and
    /// a stack losing its last window goes, leaving the master the screen.
    mutating func removeFromMaster(at path: [Int]) {
        guard let stackPath else { return root.remove(at: path[0]) }
        let stack = root.container(at: stackPath)
        if path.count == 1 {
            // The master closes; the top of the stack takes its place, keeping the master's share.
            let top = stack.children[0]
            if stack.children.count == 1 {
                root = Container(.horizontal, .tiles, [top])
            } else {
                root.modify(at: stackPath) { $0.remove(at: 0) }
                root.replace(at: path[0], with: top)
            }
        } else if stack.children.count == 1 {
            root.remove(at: stackPath[0])
        } else {
            root.modify(at: stackPath) { $0.remove(at: path[1]) }
        }
    }

    /// Switching to the master layout from another: the focused window becomes the master and the others stack in
    /// `ids` order, as an accordion if most of them were shown in one, else as tiles. Returns the master order.
    mutating func takeOverForMaster(_ ids: [WindowID]) -> [WindowID] {
        let others = ids.filter { $0 != focused }
        let inAccordions = others.filter { container(of: $0)?.mode == .accordion }.count
        stackMode = inAccordions * 2 > others.count ? .accordion : .tiles
        guard let focused, ids.contains(focused) else { return ids }
        return [focused] + others
    }

    /// Set the stack's mode, orientation or both, and keep them for a stack opened later. The stack keeps running
    /// top to bottom when it becomes an accordion, whatever `autoOrientAccordions` says, unless an orientation is given.
    mutating func setStackLayout(_ mode: LayoutMode?, _ orientation: ContainerOrientation?) {
        if let mode { stackMode = mode }
        if let orientation { stackOrientation = orientation }
        guard let stackPath else { return }
        root.modify(at: stackPath) { stack in
            stack.mode = stackMode
            stack.orientation = stackOrientation
        }
    }

    /// Give the master its configured share and the stacked windows equal ones.
    mutating func balanceMaster() {
        root.balance()
        if stackPath != nil { root.setRatios(masterRatios) }
    }

    /// Swap the focused window with the master, or the master with the top of the stack when it is focused. Both
    /// tiles keep their sizes and the focus stays with the focused window. False with nothing to swap.
    @discardableResult
    public mutating func swapWithMaster() -> Bool {
        isFullscreen = false
        guard let focused, let master = masterWindow, let stackPath else { return false }
        let other = focused == master ? root.node(at: stackPath).windows[0] : master
        return swap(focused, other)
    }

    /// Move the focused window by swapping it with its neighbour in `direction`, so the shape stays.
    mutating func moveInMaster(_ direction: Direction) -> Bool {
        guard let focused, let other = neighbor(of: focused, direction) else { return false }
        return swap(focused, other)
    }
}
