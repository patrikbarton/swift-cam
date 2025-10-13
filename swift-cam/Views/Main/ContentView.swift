//
//  ContentView.swift
//  swift-cam
//
//  Main tab navigation container
//

import SwiftUI

/// Main content view with tab-based navigation
///
/// This is the primary navigation container after app initialization,
/// coordinating three main sections:
///
/// **Tab 1: Home** - Photo library and classification
/// - Select images from photo library
/// - View classification results
/// - Apply face blurring for privacy
///
/// **Tab 2: Camera (Default)** - Live camera detection
/// - Real-time object detection
/// - Best Shot automatic capture
/// - Assisted capture mode
/// - Object highlighting
///
/// **Tab 3: Settings** - Configuration
/// - ML model selection
/// - Camera settings
/// - Privacy options
/// - System information
///
/// **Architecture:**
/// Each tab has its own ViewModel and maintains independent state.
/// `AppStateViewModel` is shared across all tabs for global settings.
///
/// **UI Theme:**
/// Uses "Liquid Glass" dark mode aesthetic with `.appAccent` tint color.
struct ContentView: View {
    
    // MARK: - State
    
    /// Currently selected tab (0=Home, 1=Camera, 2=Settings)
    @State private var selectedTab = 1 // Default to Camera tab
    
    /// ViewModel for photo classification (used by Home and Settings)
    @StateObject private var cameraViewModel = HomeViewModel()
    
    /// Global app state coordinator (initialization + settings)
    @StateObject private var appStateViewModel = AppStateViewModel()
    
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
}
