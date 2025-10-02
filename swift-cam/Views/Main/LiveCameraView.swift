//
//  LiveCameraView.swift
//  swift-cam
//
//  Live camera view with real-time classification
//

import SwiftUI

struct LiveCameraView: View {
    @ObservedObject var cameraManager: CameraViewModel
    let selectedModel: MLModelType
    @Environment(\.dismiss) private var dismiss
    @StateObject private var liveCameraManager = LiveCameraViewModel()
    
    var body: some View {
        ZStack {
            // Native Camera
            NativeCameraView(
                onImageCaptured: { image in
                    Task {
                        await cameraManager.classifyImage(image)
                        dismiss()
                    }
                },
                onDismiss: {
                    dismiss()
                }
            )
            
            // Modern overlay
            VStack {
                Spacer()
                
                if !liveCameraManager.liveResults.isEmpty {
                    ModernLiveResultsOverlay(
                        results: liveCameraManager.liveResults,
                        isProcessing: liveCameraManager.isProcessing
                    )
                    .padding(.bottom, 140)
                }
            }
            .allowsHitTesting(false)
        }
        .onAppear {
            liveCameraManager.updateModel(to: selectedModel)
            liveCameraManager.startSession()
        }
        .onDisappear {
            liveCameraManager.stopSession()
        }
    }
}

