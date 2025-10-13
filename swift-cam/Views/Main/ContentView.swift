//
//  ContentView.swift
//  swift-cam
//
//  Main view with tab navigation
//
//  This is the app's main entry point, coordinating between three tabs:
//  - Home: Photo library selection and classification
//  - Camera: Live camera with real-time ML detection
//  - Settings: Model selection and app configuration

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 1 // Default to Camera tab
    @StateObject private var cameraViewModel = HomeViewModel()
    @StateObject private var appStateViewModel = AppStateViewModel()
    
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
