//
//  CameraTabView.swift
//  swift-cam
//
//  Camera tab view that embeds the live camera
//

import SwiftUI

/// Camera tab that directly embeds LiveCameraView
struct CameraTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedTab: Int
    @ObservedObject var appStateViewModel: AppStateViewModel
    @StateObject private var liveCameraManager = LiveCameraViewModel()
    
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
