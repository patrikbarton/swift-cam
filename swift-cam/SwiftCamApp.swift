//
//  SwiftCamApp.swift
//  swift-cam
//
//  Main app entry point and lifecycle management
//

import SwiftUI

/// Main application entry point for Swift-Cam
///
/// This is the root of the app that:
/// - Initializes the app state and coordinates model preloading
/// - Shows splash screen during initialization
/// - Transitions to main content when ready
/// - Forces portrait orientation for optimal camera experience
///
/// **App Architecture:**
/// ```
/// SwiftCamApp
///   ├─ SplashScreenView (while isLoading)
///   │   └─ Preloads all ML models
///   └─ ContentView (after loading)
///       └─ Tab navigation to Home/Camera/Settings
/// ```
///
/// **State Management:**
/// - Uses `AppStateViewModel` as single source of truth
/// - Injects via `@EnvironmentObject` for global access
/// - Coordinates initialization sequence
///
/// **ML Model Preloading:**
/// All three models (MobileNet, ResNet, FastViT) are preloaded during
/// splash screen (~2 seconds) for instant access when user switches models.
@main
struct SwiftCamApp: App {
    
    /// App state coordinator managing initialization and settings
    @StateObject private var appState = AppStateViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoading {
                // Show splash while preloading models
                SplashScreenView()
                    .environmentObject(appState)
            } else {
                // Main app content after initialization
                ContentView()
                    .environmentObject(appState)
            }
        }
    }
}

/// App delegate to manage orientation lock
class AppDelegate: NSObject, UIApplicationDelegate {
    
    /// Restricts app to portrait orientation only
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}
