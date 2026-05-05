//
//  sunstake_appApp.swift
//  sunstake-app
//
//  Created by Andrés Rodríguez Montes de Oca on 04/05/26.
//

import SwiftUI

@main
struct sunstake_appApp: App {
    @State private var appState = AppState()
    @State private var accessibility = AccessibilityPreferences()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(accessibility)
                .preferredColorScheme(accessibility.colorScheme.colorScheme)
                .dynamicTypeSize(accessibility.fontSize.dynamicTypeSize)
                .colorBlindFilter(accessibility.colorBlindMode)
        }
    }
}

