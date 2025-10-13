//
//  SwiftCamApp.swift
//  swift-cam
//
//  Created by Patrik Barton on 22.09.25.
//

import SwiftUI

@main
struct SwiftCamApp: App {
    @StateObject private var appState = AppStateViewModel()
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoading {
                SplashScreenView()
                    .environmentObject(appState)
            } else {
                ContentView()
                    .environmentObject(appState)
            }
        }
    }
}
