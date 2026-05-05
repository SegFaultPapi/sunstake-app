import SwiftUI

@main
struct SunstakeApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - Design System

extension Color {
    static let sunYellow   = Color(red: 1.0,  green: 0.78, blue: 0.0)
    static let sunOrange   = Color(red: 1.0,  green: 0.5,  blue: 0.1)
    static let chainIndigo = Color(red: 0.27, green: 0.27, blue: 0.80)
    static let surfaceGray = Color(UIColor.secondarySystemBackground)
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
}

extension Font {
    static let sunTitle   = Font.system(.title2, design: .rounded, weight: .bold)
    static let sunHeading = Font.system(.headline, design: .rounded, weight: .semibold)
    static let sunBody    = Font.system(.body, design: .rounded)
    static let sunCaption = Font.system(.caption, design: .rounded)
}
