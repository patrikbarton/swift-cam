//
//  LiveCameraView.swift
//  swift-cam
//
//  Live camera view with real-time classification (Square Camera Design)
//

import SwiftUI

struct LiveCameraView: View {
    @ObservedObject var cameraManager: CameraViewModel
    let selectedModel: MLModelType
    @ObservedObject var appStateViewModel: AppStateViewModel // Observe changes instead of copying value
    @Environment(\.dismiss) private var dismiss
    @StateObject private var liveCameraManager: LiveCameraViewModel
    let onCustomDismiss: (() -> Void)? // Optional custom dismiss for embedded mode

    @State private var showLowResPreview = false

    init(cameraManager: CameraViewModel, selectedModel: MLModelType, appStateViewModel: AppStateViewModel, liveCameraManager: LiveCameraViewModel = LiveCameraViewModel(), onCustomDismiss: (() -> Void)? = nil) {
        self.cameraManager = cameraManager
        self.selectedModel = selectedModel
        self.appStateViewModel = appStateViewModel
        _liveCameraManager = StateObject(wrappedValue: liveCameraManager)
        self.onCustomDismiss = onCustomDismiss
    }
    
    // Computed property for easy access
    private var fullScreenCamera: Bool {
        appStateViewModel.fullScreenCamera
    }
    
    private func handleDismiss() {
        if let onCustomDismiss = onCustomDismiss {
            onCustomDismiss()
        } else {
            dismiss()
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if fullScreenCamera {
                // --- FULL SCREEN CAMERA LAYOUT ---
                ZStack {
                    // Camera Preview Layer (Full Screen)
                    CameraPreviewView(session: liveCameraManager.session)
                        .ignoresSafeArea()
                    
                    // Low-resolution Overlay (Debug Mode)
                    if showLowResPreview, let image = liveCameraManager.lowResPreviewImage {
                        GeometryReader { geometry in
                            Image(uiImage: image)
                                .resizable()
                                .interpolation(.none) // Makes it pixelated
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .transition(.opacity)
                        }
                        .ignoresSafeArea()
                    }
                    
                    // UI Overlay Layer
                    VStack {
                        Spacer()
                        Spacer() // Extra spacer to push content down
                        
                        // Results Overlay (positioned lower, not blocking screen)
                        VStack(spacing: 0) {
                            LiveClassificationResultsView(
                                results: liveCameraManager.liveResults,
                                model: selectedModel
                            )
                            .frame(height: 180)
                            .padding(.horizontal)
                            .padding(.bottom, 80) // Lower positioning - more visible screen
                            
                            // Bottom Controls - Centered Capture Button
                            ZStack {
                                // Side Controls
                                HStack {
                                    // Left Side
                                    ZoomControlView(manager: liveCameraManager)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    // Right Side
                                    HStack(spacing: 12) {
                                        Toggle(isOn: $showLowResPreview) {
                                            Image(systemName: "eye.square")
                                                .font(.system(size: 20, weight: .medium))
                                                .foregroundColor(showLowResPreview ? .yellow : .white)
                                        }
                                        .toggleStyle(.button)
                                        .clipShape(Circle())
                                        .tint(Color.black.opacity(0.5))
                                        .onChange(of: showLowResPreview) { _, newValue in
                                            liveCameraManager.showLowResPreview = newValue
                                        }
                                        
                                        Button(action: { liveCameraManager.switchCamera() }) {
                                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                                .font(.system(size: 20, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(12)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                    }
                                    .frame(width: 100, alignment: .trailing)
                                }
                                .padding(.horizontal)
                                
                                // Centered Capture Button
                                CaptureButton {
                                    liveCameraManager.capturePhoto { image in
                                        if let image = image {
                                            Task { await cameraManager.classifyImage(image, applyFaceBlur: appStateViewModel.faceBlurringEnabled, blurStyle: appStateViewModel.blurStyle) }
                                        }
                                        handleDismiss()
                                    }
                                }
                            }
                            .padding(.bottom, 80)
                        }
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            } else {
                // --- SQUARE CAMERA LAYOUT (Original) ---
                VStack(spacing: 0) {
                    // --- 1. CAMERA BLOCK (Square 1:1) ---
                    GeometryReader { geometry in
                        ZStack {
                            // Camera Preview Layer with .resizeAspectFill
                            CameraPreviewView(session: liveCameraManager.session)
                                .clipShape(Rectangle())

                            // Low-resolution Overlay (Debug Mode)
                            if showLowResPreview, let image = liveCameraManager.lowResPreviewImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .interpolation(.none) // Makes it pixelated
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                                    .transition(.opacity)
                            }

                            // UI Overlay Layer
                            VStack {
                                Spacer()
                                Spacer() // Extra spacer to push content down

                                HStack {
                                    ZoomControlView(manager: liveCameraManager)
                                    Spacer()

                                    // Toggle for low-resolution preview
                                    Toggle(isOn: $showLowResPreview) {
                                        Image(systemName: "eye.square")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(showLowResPreview ? .yellow : .white)
                                    }
                                    .toggleStyle(.button)
                                    .clipShape(Circle())
                                    .tint(Color.black.opacity(0.4))
                                    .onChange(of: showLowResPreview) { _, newValue in
                                        liveCameraManager.showLowResPreview = newValue
                                    }

                                    Button(action: { liveCameraManager.switchCamera() }) {
                                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(Color.black.opacity(0.4))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .aspectRatio(1.0, contentMode: .fit)

                    // --- 2. RESULTS BLOCK (positioned lower) ---
                    LiveClassificationResultsView(
                        results: liveCameraManager.liveResults,
                        model: selectedModel
                    )
                    .frame(height: 180) // Fixed height for stability
                    .padding()
                    .padding(.bottom, 40) // Lower positioning - more visible screen

                    // --- 3. CAPTURE BUTTON ---
                    Spacer()

                    HStack {
                        Spacer()
                        CaptureButton {
                            liveCameraManager.capturePhoto { image in
                                if let image = image {
                                    Task { await cameraManager.classifyImage(image, applyFaceBlur: appStateViewModel.faceBlurringEnabled, blurStyle: appStateViewModel.blurStyle) }
                                }
                                handleDismiss()
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom)
                }
            }
        }
        .onAppear {
            liveCameraManager.updateModel(to: selectedModel)
            liveCameraManager.faceBlurringEnabled = appStateViewModel.faceBlurringEnabled
            liveCameraManager.blurStyle = appStateViewModel.blurStyle
            liveCameraManager.startSession()
        }
        .onDisappear {
            liveCameraManager.stopSession()
        }
        .onChange(of: appStateViewModel.faceBlurringEnabled) { _, newValue in
            liveCameraManager.faceBlurringEnabled = newValue
        }
        .onChange(of: appStateViewModel.blurStyle) { _, newValue in
            liveCameraManager.blurStyle = newValue
        }
    }
}

#if DEBUG
class MockCameraViewModel: CameraViewModel {}

class MockLiveCameraViewModelForPreview: LiveCameraViewModel {
    override func startSession() {
        // Do nothing to prevent camera access in preview
    }
}

#Preview {
    LiveCameraView(cameraManager: MockCameraViewModel(), selectedModel: .mobileNet, appStateViewModel: AppStateViewModel(), liveCameraManager: MockLiveCameraViewModelForPreview())
}
#endif

