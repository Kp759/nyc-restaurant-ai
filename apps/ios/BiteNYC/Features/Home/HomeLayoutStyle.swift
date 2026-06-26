import SwiftUI

/// Home screen layout variants for side-by-side comparison.
enum HomeLayoutStyle: String, CaseIterable, Identifiable {
    case classic
    case editorial
    case minimal

    var id: String { rawValue }

    var label: String {
        switch self {
        case .classic: return "Classic"
        case .editorial: return "Editorial"
        case .minimal: return "Minimal"
        }
    }

    var blurb: String {
        switch self {
        case .classic: return "Bold hero, stacked cards"
        case .editorial: return "Light rails, swipe vibes"
        case .minimal: return "Compact, clean, less noise"
        }
    }
}
