import SwiftUI

// MARK: - Color tokens

extension Color {
    static let sunYellow   = Color(red: 1.0,  green: 0.78, blue: 0.0)
    static let sunOrange   = Color(red: 1.0,  green: 0.5,  blue: 0.1)
    static let chainIndigo = Color(red: 0.27, green: 0.27, blue: 0.80)
    static let surfaceGray = Color(UIColor.secondarySystemBackground)
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
}

// MARK: - ShapeStyle dot-syntax support for foregroundStyle(_:)

extension ShapeStyle where Self == Color {
    static var sunYellow:    Color { .sunYellow }
    static var sunOrange:    Color { .sunOrange }
    static var chainIndigo:  Color { .chainIndigo }
    static var surfaceGray:  Color { .surfaceGray }
    static var textPrimary:  Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
}

// MARK: - Font tokens

extension Font {
    static let sunTitle   = Font.system(.title2,   design: .rounded, weight: .bold)
    static let sunHeading = Font.system(.headline,  design: .rounded, weight: .semibold)
    static let sunBody    = Font.system(.body,       design: .rounded)
    static let sunCaption = Font.system(.caption,   design: .rounded)
}
