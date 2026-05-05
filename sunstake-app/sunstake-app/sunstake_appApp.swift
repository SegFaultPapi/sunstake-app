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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.light)
        }
    }
}

