import SwiftUI

enum Theme {
    static let accent = Color(red: 1.0, green: 0.35, blue: 0.24) // BiteNYC orange
    static let accentBlue = Color(red: 0.31, green: 0.55, blue: 1.0)
    static let good = Color(red: 0.21, green: 0.79, blue: 0.55)
    static let warn = Color(red: 0.96, green: 0.73, blue: 0.26)
    static let bad = Color(red: 1.0, green: 0.36, blue: 0.42)

    static let cardBackground = Color(.secondarySystemBackground)
    static let chipBackground = Color(.tertiarySystemBackground)
}

extension Color {
    /// Letter-grade tint for NYC DOHMH health grades.
    static func healthGrade(_ grade: String?) -> Color {
        switch grade?.uppercased() {
        case "A": return Theme.good
        case "B": return Theme.warn
        case "C": return Theme.bad
        default: return .secondary
        }
    }
}
