import SwiftUI

@Observable
final class AccessibilityPreferences {

    // MARK: - Types

    enum AppColorScheme: String, CaseIterable, Identifiable {
        case system = "Sistema"
        case light  = "Claro"
        case dark   = "Oscuro"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light:  return "sun.max"
            case .dark:   return "moon.stars"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light:  return .light
            case .dark:   return .dark
            }
        }
    }

    enum FontSizeOption: String, CaseIterable, Identifiable {
        case small      = "Pequeño"
        case medium     = "Mediano"
        case large      = "Grande"
        case extraLarge = "Muy grande"
        var id: String { rawValue }
        var dynamicTypeSize: DynamicTypeSize {
            switch self {
            case .small:      return .small
            case .medium:     return .large
            case .large:      return .xLarge
            case .extraLarge: return .xxLarge
            }
        }
    }

    enum ColorBlindMode: String, CaseIterable, Identifiable {
        case none          = "Ninguno"
        case protanopia    = "Protanopia (rojo)"
        case deuteranopia  = "Deuteranopia (verde)"
        case monochromacy  = "Monocromático"
        var id: String { rawValue }
    }

    // MARK: - State (persisted via UserDefaults)

    var colorScheme: AppColorScheme {
        didSet { UserDefaults.standard.set(colorScheme.rawValue, forKey: Keys.colorScheme) }
    }
    var fontSize: FontSizeOption {
        didSet { UserDefaults.standard.set(fontSize.rawValue, forKey: Keys.fontSize) }
    }
    var colorBlindMode: ColorBlindMode {
        didSet { UserDefaults.standard.set(colorBlindMode.rawValue, forKey: Keys.colorBlindMode) }
    }

    init() {
        let sRaw = UserDefaults.standard.string(forKey: Keys.colorScheme) ?? ""
        colorScheme = AppColorScheme(rawValue: sRaw) ?? .system
        let fRaw = UserDefaults.standard.string(forKey: Keys.fontSize) ?? ""
        fontSize = FontSizeOption(rawValue: fRaw) ?? .medium
        let cRaw = UserDefaults.standard.string(forKey: Keys.colorBlindMode) ?? ""
        colorBlindMode = ColorBlindMode(rawValue: cRaw) ?? .none
    }

    // MARK: - Keys
    private enum Keys {
        static let colorScheme    = "acc_colorScheme"
        static let fontSize       = "acc_fontSize"
        static let colorBlindMode = "acc_colorBlindMode"
    }
}

// MARK: - View modifier that applies color-blind filter

struct ColorBlindModifier: ViewModifier {
    let mode: AccessibilityPreferences.ColorBlindMode

    func body(content: Content) -> some View {
        content
            .grayscale(mode == .monochromacy ? 1.0 : 0.0)
            .hueRotation(.degrees(mode == .protanopia ? -90 : mode == .deuteranopia ? 60 : 0))
            .saturation(mode == .protanopia ? 0.6 : mode == .deuteranopia ? 0.55 : 1.0)
    }
}

extension View {
    func colorBlindFilter(_ mode: AccessibilityPreferences.ColorBlindMode) -> some View {
        modifier(ColorBlindModifier(mode: mode))
    }
}
