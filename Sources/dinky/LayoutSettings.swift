import DinkyConfig
import DinkyLayout

// How a workspace's settings in the config map onto the layout engine.
extension WorkspaceSettings {
    /// The tiling algorithm the settings ask for, a master layout's side taken from `master`.
    func algorithm(_ master: Master) -> TilingAlgorithm {
        let expand: FixedExpansion = switch self.expand {
        case .rows: .rows
        case .columns: .columns
        case .accordion: .accordion
        }
        return switch layout {
        case .tiles, .dwindle: .dwindle(.tiles)
        case .accordion: .dwindle(.accordion)
        case .fixed: .fixed(rows: rows, columns: columns, expand: expand)
        case .scrolling: .scrolling
        case .master: .master(master.orientation == .left ? .left : .right)
        }
    }
}
