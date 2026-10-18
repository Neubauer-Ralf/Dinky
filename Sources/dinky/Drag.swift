import AppKit
import DinkyLayout

// Dragging a tiled window with the mouse. On release, a drag that moved one edge of the window on an axis is a
// resize: the tree takes the new size and the other tiles make room. Any other drag is a move: dropping it with the
// pointer over another tile swaps the two, anywhere else puts it back. While a move is under way, placeholders
// outline the window's tile and the one it would swap with. Only frames that change while the mouse button is
// down count as a drag, which keeps dinky's own frame writes and apps moving themselves out of it.
extension Coordinator {
    func noteFrameChange(of id: WindowID) {
        if dragging == id { return showPlaceholders() }
        // Only tiled windows have a Space. Disabled, dinky leaves drags alone.
        guard enabled, dragging == nil, let key = placements[id]?.space, !isAnimating(id), mouseButtonDown,
              let tile = workspaces[key]?.layout().frames[id] else { return }
        dragging = id
        dragStart = tile
        showPlaceholders()
        watchDragEnd()
    }

    private func watchDragEnd() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self, let id = self.dragging, let start = self.dragStart else { return }
            if self.mouseButtonDown {
                self.showPlaceholders()
                self.watchDragEnd()
            } else {
                (self.dragging, self.dragStart) = (nil, nil)
                self.placeholders.hide()
                self.dropped(id, from: start)
            }
        }
    }

    /// Lets go of the drag under way without acting on its release, as when dinky is disabled mid-drag.
    func cancelDrag() {
        guard dragging != nil else { return }
        (dragging, dragStart) = (nil, nil)
        placeholders.hide()
    }

    /// Resizes or swaps by how the window moved from `start`, its tile when the drag began. Either way, or when it
    /// went back where it started, it then goes to its tile, which may have changed during the drag.
    private func dropped(_ id: WindowID, from start: CGRect) {
        guard let key = placements[id]?.space, let layout = workspaces[key]?.layout(), let window = model.windows[id],
              let expected = layout.frames[id] else { return }
        if !window.frame.isClose(to: start, within: 2) {
            if let edges = movedEdges(from: start, to: window.frame) {
                edit(key) { $0.resize(id, to: window.frame.size, moving: edges) }
            } else if let target = dropTarget(of: id, in: layout) {
                edit(key) { $0.swap(id, target) }
            }
        } else if window.frame.isClose(to: expected, within: 2) {
            return
        }
        dirty.insert(key)
        flush()
    }

    /// Outline the dragged window's tile and the tile it would swap with, while the drag is a move.
    private func showPlaceholders() {
        guard config.drag.placeholders, let id = dragging, let start = dragStart, let key = placements[id]?.space,
              let layout = workspaces[key]?.layout(), let home = layout.frames[id], let window = model.windows[id],
              !window.frame.isClose(to: start, within: 2), movedEdges(from: start, to: window.frame) == nil
        else { return placeholders.hide() }
        placeholders.show(dragged: id, home: home, target: dropTarget(of: id, in: layout).flatMap { layout.frames[$0] },
                          cornerRadius: CGFloat(window.cornerRadius))
    }

    /// The tile under the pointer that a dragged window swaps with, the frontmost where tiles overlap. The
    /// placeholders and the drop both ask this, so what is outlined is what happens.
    private func dropTarget(of id: WindowID, in layout: Layout) -> WindowID? {
        guard let pointer = CGEvent(source: nil)?.location else { return nil }
        return layout.order.first { $0 != id && layout.frames[$0]!.contains(pointer) }
    }

    /// The edges a resize moved, going from the tile to the dropped frame: on each axis, one edge moved more than
    /// 2 pt and the other stayed. Nil for a move, where some axis had both edges move, or nothing did.
    private func movedEdges(from tile: CGRect, to frame: CGRect) -> Set<Direction>? {
        let axes = [((Direction.left, tile.minX, frame.minX), (Direction.right, tile.maxX, frame.maxX)),
                    ((Direction.up, tile.minY, frame.minY), (Direction.down, tile.maxY, frame.maxY))]
        var edges: Set<Direction> = []
        for (lead, trail) in axes {
            let moved = [lead, trail].filter { abs($0.2 - $0.1) > 2 }.map(\.0)
            if moved.count == 2 { return nil }
            edges.formUnion(moved)
        }
        return edges.isEmpty ? nil : edges
    }

    private var mouseButtonDown: Bool { CGEventSource.buttonState(.combinedSessionState, button: .left) }
}
