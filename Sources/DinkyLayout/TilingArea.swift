import CoreGraphics

/// The area to tile in on a display, in CG coordinates (top-left origin): its `visible` area, or when
/// `ignoringDock`, everything from the top of the visible area (below the menu bar) to the display's other edges.
///
/// With the Dock set to auto-hide, macOS should reserve only a few points for it, but after Mission Control it can
/// keep reporting the shown Dock's whole strip for a minute or more, until the Dock is restarted.
public func tilingArea(frame: CGRect, visible: CGRect, ignoringDock: Bool) -> CGRect {
    guard ignoringDock else { return visible }
    return CGRect(x: frame.minX, y: visible.minY, width: frame.width, height: frame.maxY - visible.minY)
}
