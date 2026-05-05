import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64

        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1.0
        )
    }

    func adjust(hue: CGFloat = 0, saturation: CGFloat = 0, lightness: CGFloat = 0) -> Color {
        let uiColor = UIColor(self)

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        var h: CGFloat = 0
        var s: CGFloat = 0
        let l: CGFloat = (maxC + minC) / 2

        if delta != 0 {
            s = delta / (1 - abs(2 * l - 1))

            switch maxC {
            case r: h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            case g: h = (b - r) / delta + 2
            default: h = (r - g) / delta + 4
            }

            h /= 6
            if h < 0 { h += 1 }
        }

        let newH = min(max(h + hue, 0), 1)
        let newS = min(max(s + saturation, 0), 1)
        let newL = min(max(l + lightness, 0), 1)

        let c = (1 - abs(2 * newL - 1)) * newS
        let x = c * (1 - abs((newH * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = newL - c / 2

        var rOut, gOut, bOut: CGFloat

        switch newH * 6 {
        case 0..<1: (rOut, gOut, bOut) = (c, x, 0)
        case 1..<2: (rOut, gOut, bOut) = (x, c, 0)
        case 2..<3: (rOut, gOut, bOut) = (0, c, x)
        case 3..<4: (rOut, gOut, bOut) = (0, x, c)
        case 4..<5: (rOut, gOut, bOut) = (x, 0, c)
        default:    (rOut, gOut, bOut) = (c, 0, x)
        }

        return Color(UIColor(red: rOut + m, green: gOut + m, blue: bOut + m, alpha: a))
    }
}

struct ColorPalette {
    let base: Color

    var c300: Color { base.adjust(saturation: -0.05, lightness: 0.15) }
    var c400: Color { base.adjust(lightness: 0.07) }
    var c500: Color { base }
    var c600: Color { base.adjust(saturation: -0.05, lightness: -0.10) }
    var c700: Color { base.adjust(saturation: -0.10, lightness: -0.15) }
}

// MARK: - Sunstake palette
//
// To add a new brand color: declare a `base` Color and a private `ColorPalette`,
// then expose the c300–c700 shades following the `primary` / `secondary` /
// `chain` pattern. Semantic surface and text tokens live at the bottom of this
// extension and resolve to system colors so dark mode works automatically.

extension Color {
    static let primaryBase   = Color(hex: "#FFE6A7")  // warm yellow
    static let secondaryBase = Color(hex: "#FF773D")  // accent orange
    static let chainBase     = Color(hex: "#4545CC")  // blockchain indigo

    private static let primaryPalette   = ColorPalette(base: primaryBase)
    private static let secondaryPalette = ColorPalette(base: secondaryBase)
    private static let chainPalette     = ColorPalette(base: chainBase)

    static let primary300 = primaryPalette.c300
    static let primary400 = primaryPalette.c400
    static let primary500 = primaryPalette.c500
    static let primary600 = primaryPalette.c600
    static let primary700 = primaryPalette.c700

    static let secondary300 = secondaryPalette.c300
    static let secondary400 = secondaryPalette.c400
    static let secondary500 = secondaryPalette.c500
    static let secondary600 = secondaryPalette.c600
    static let secondary700 = secondaryPalette.c700

    static let chain300 = chainPalette.c300
    static let chain400 = chainPalette.c400
    static let chain500 = chainPalette.c500
    static let chain600 = chainPalette.c600
    static let chain700 = chainPalette.c700

    // System-aware semantic tokens (adapt to dark mode automatically)
    static let surface        = Color(UIColor.secondarySystemBackground)
    static let textPrimary    = Color(UIColor.label)
    static let textSecondary  = Color(UIColor.secondaryLabel)

    // Status — hex fijos para WCAG AA en ambos modos
    static let success = Color(hex: "#22C55E")
    static let warning = Color(hex: "#F59E0B")
    static let danger  = Color(hex: "#EF4444")
}

// MARK: - Spacing tokens (4pt grid)

enum DSSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Radius tokens

enum DSRadius {
    static let sm:   CGFloat = 10   // chips, inner rows
    static let md:   CGFloat = 14   // inputs, buttons
    static let lg:   CGFloat = 18   // primary cards
    static let pill: CGFloat = 999  // capsule alias
}

// MARK: - Font tokens
//
// 9-level scale: Display(44) › Number(36) › Title(22) › Heading(17) ›
//                Subhead(15) › Body(16) › Footnote(13) › Caption(12) › Caption2(11)
//
// dsBody usa .callout (16pt) en lugar de .body (17pt) para separarse
// visualmente de dsHeading (17pt semibold) y crear jerarquía real.

extension Font {
    // Hero financial figures — cuota principal, yield total, monto de inversión
    static let dsDisplay  = Font.system(size: 44, weight: .bold,      design: .rounded)
    // Secondary large numbers — ring de propiedad, totales secundarios
    static let dsNumber   = Font.system(size: 36, weight: .bold,      design: .rounded)
    // Screen section headers
    static let dsTitle    = Font.system(.title2,      design: .rounded, weight: .bold)
    // Card titles, primary interactive labels
    static let dsHeading  = Font.system(.headline,    design: .rounded, weight: .semibold)
    // Descriptive subtitles and metadata (15pt vs 17pt heading → jerarquía clara)
    static let dsSubhead  = Font.system(.subheadline, design: .rounded, weight: .medium)
    // Readable paragraphs (16pt callout, 1pt abajo de heading para diferenciarse)
    static let dsBody     = Font.system(.callout,     design: .rounded)
    // Supporting context, source labels
    static let dsFootnote = Font.system(.footnote,    design: .rounded)
    // Chips, data labels
    static let dsCaption  = Font.system(.caption,     design: .rounded)
    // Minimal labels, compliance text — formaliza el .caption2 ad-hoc
    static let dsCaption2 = Font.system(.caption2,    design: .rounded)
}

// MARK: - ShapeStyle dot-syntax (lets call sites use `.foregroundStyle(.chain500)`).
// Incluye tokens de fuente para uso en `.font(.dsDisplay)` etc.

extension ShapeStyle where Self == Color {
    static var primary300:  Color { .primary300 }
    static var primary400:  Color { .primary400 }
    static var primary500:  Color { .primary500 }
    static var primary600:  Color { .primary600 }
    static var primary700:  Color { .primary700 }

    static var secondary300: Color { .secondary300 }
    static var secondary400: Color { .secondary400 }
    static var secondary500: Color { .secondary500 }
    static var secondary600: Color { .secondary600 }
    static var secondary700: Color { .secondary700 }

    static var chain300: Color { .chain300 }
    static var chain400: Color { .chain400 }
    static var chain500: Color { .chain500 }
    static var chain600: Color { .chain600 }
    static var chain700: Color { .chain700 }

    static var surface:        Color { .surface }
    static var textPrimary:    Color { .textPrimary }
    static var textSecondary:  Color { .textSecondary }

    static var success: Color { .success }
    static var warning: Color { .warning }
    static var danger:  Color { .danger }
}
