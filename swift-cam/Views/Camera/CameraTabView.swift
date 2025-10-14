//
//  CameraTabView.swift
//  swift-cam
//
//  The main container view for the "Camera" tab.
//

import SwiftUI

/// A thin wrapper that hosts the `LiveCameraView` within the app's main `TabView`.
///
/// This view's primary responsibility is to manage the lifecycle of the `LiveCameraViewModel`,
/// creating a new instance each time the user switches to the Camera tab. It ensures the
/// live camera session is active only when this tab is visible.
///
/// **UI Layout:**
/// This view itself has no visible UI other than what is provided by `LiveCameraView`.
/// It configures the safe area to allow the camera preview to extend to the top edge
/// of the screen while keeping the main tab bar visible at the bottom.
///
/// **State Management:**
/// - Creates and owns the `LiveCameraViewModel` as a `@StateObject`, tying the camera session lifecycle to this tab.
/// - Passes the shared `AppStateViewModel` down to the `LiveCameraView`.
/// - Injects a custom dismiss handler to change tabs rather than dismissing the view itself.
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
        .onAppear(perform: liveCameraManager.startSession)
        .onDisappear(perform: liveCameraManager.stopSession)
        .ignoresSafeArea(.all, edges: .top) // Full screen camera but tab bar visible
    }
}
