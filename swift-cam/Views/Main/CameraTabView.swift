//
//  CameraTabView.swift
//  swift-cam
//
//  Camera tab that embeds live camera view
//

import SwiftUI

/// Camera tab that directly embeds LiveCameraView
///
/// This is a thin wrapper that embeds the live camera experience
/// within the tab navigation structure.
///
/// **Responsibilities:**
/// - Instantiate LiveCameraViewModel
/// - Pass through global app state
/// - Handle custom dismiss (return to Home tab)
/// - Maintain tab bar visibility
///
/// **Integration:**
/// The camera view is embedded with `.ignoresSafeArea` on top edge
/// to maximize camera preview area while keeping tab bar visible.
///
/// **Navigation:**
/// Custom dismiss handler returns to Home tab instead of dismissing
/// the entire view, since this is embedded in TabView navigation.
struct CameraTabView: View {
    
    // MARK: - Dependencies
    
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedTab: Int
    @ObservedObject var appStateViewModel: AppStateViewModel
    
    /// Live camera manager (created per tab selection)
    @StateObject private var liveCameraManager = LiveCameraViewModel()
    
    // MARK: - Body
    
    var body: some View {
        // Camera directly embedded in tab - Tab Bar stays visible!
        LiveCameraView(
            selectedModel: appStateViewModel.selectedModel, 
            appStateViewModel: appStateViewModel,
            liveCameraManager: liveCameraManager,
            onCustomDismiss: {
                // When back button pressed, go back to Home tab
                selectedTab = 0
            }
        )
        .ignoresSafeArea(.all, edges: .top) // Full screen camera but tab bar visible
    }
}
