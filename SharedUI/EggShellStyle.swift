import RunimalCore
import SwiftUI

extension EggShellType {
    var accentColor: Color {
        switch self {
        case .ember:
            return Color(red: 0.97, green: 0.38, blue: 0.28)
        case .gale:
            return Color(red: 0.39, green: 0.75, blue: 0.98)
        case .moss:
            return Color(red: 0.45, green: 0.78, blue: 0.49)
        case .dusk:
            return Color(red: 0.57, green: 0.49, blue: 0.95)
        case .stone:
            return Color(red: 0.67, green: 0.60, blue: 0.54)
        }
    }

    var displayLabel: String {
        RunimalEggEngine.shellLabel(for: self)
    }

    var hatchHint: String {
        RunimalEggEngine.hint(for: self)
    }

    var scanHeadline: String {
        RunimalEggEngine.scanHeadline(for: self)
    }

    var scanLogLines: [String] {
        RunimalEggEngine.scanLogLines(for: self)
    }

    var shellTint: Color {
        switch self {
        case .ember:
            return Color(red: 1.0, green: 0.58, blue: 0.24)
        case .gale:
            return Color(red: 0.82, green: 0.95, blue: 1.0)
        case .moss:
            return Color(red: 0.24, green: 0.50, blue: 0.23)
        case .dusk:
            return Color(red: 0.34, green: 0.18, blue: 0.52)
        case .stone:
            return Color(red: 0.56, green: 0.50, blue: 0.44)
        }
    }

    var particleColor: Color {
        switch self {
        case .ember:
            return Color(red: 1.0, green: 0.84, blue: 0.42)
        case .gale:
            return Color(red: 0.74, green: 0.93, blue: 1.0)
        case .moss:
            return Color(red: 0.65, green: 0.90, blue: 0.58)
        case .dusk:
            return Color(red: 0.77, green: 0.68, blue: 1.0)
        case .stone:
            return Color(red: 0.86, green: 0.82, blue: 0.74)
        }
    }
}
