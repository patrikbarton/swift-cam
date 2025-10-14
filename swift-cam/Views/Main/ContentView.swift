//
//  ContentView.swift
//  swift-cam
//
//  Main tab navigation container
//

import SwiftUI

/// The root view of the application after the splash screen.
///
/// This view establishes the main `TabView` navigation structure, providing access
/// to the three core sections of the app: Home, Camera, and Settings.
///
/// **UI Layout:**
/// ```
/// ┌───────────────────────────┐
/// │                           │
/// │      [Active Tab View]      │
/// │                           │
/// │                           │
/// ├───────────────────────────┤
/// │ [Home]  [Camera] [Settings] │  <- TabBar
/// └───────────────────────────┘
/// ```
///
/// **State Management:**
/// - Receives the shared `AppStateViewModel` as an `@EnvironmentObject` to pass down to child tabs.
/// - Creates and owns the `HomeViewModel` which is shared between the Home and Settings tabs.
/// - Manages the currently selected tab via local `@State`.
///
/// **Tabs:**
/// 1. **Home:** Photo library and past classification results.
/// 2. **Camera:** The main live camera interface (default tab).
/// 3. **Settings:** App configuration.
struct ContentView: View {
    
    // MARK: - State
    
    /// Currently selected tab (0=Home, 1=Camera, 2=Settings)
    @State private var selectedTab = 1 // Default to Camera tab
    
    /// ViewModel for photo classification (used by Home and Settings)
    @StateObject private var cameraViewModel = HomeViewModel()
    
    /// Global app state coordinator (received from environment)
    @EnvironmentObject private var appStateViewModel: AppStateViewModel
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Photo Library & Classification Results
            HomeTabView(
                viewModel: cameraViewModel,
                appStateViewModel: appStateViewModel
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Camera Tab - Live Camera with Real-time Detection
            CameraTabView(
                viewModel: cameraViewModel,
                selectedTab: $selectedTab,
                appStateViewModel: appStateViewModel
            )
            .tabItem {
                Label("Camera", systemImage: "camera.fill")
            }
            .tag(1)
            
            // Settings Tab - Model Selection & Configuration
            SettingsTabView(
                viewModel: cameraViewModel,
                appStateViewModel: appStateViewModel
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .tint(.appAccent)
        .preferredColorScheme(.dark) // Liquid Glass theme looks best in dark mode
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateViewModel())
}
