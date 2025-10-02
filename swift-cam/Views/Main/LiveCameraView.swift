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
    @Environment(\.dismiss) private var dismiss
    @StateObject private var liveCameraManager = LiveCameraViewModel()

    @State private var showLowResPreview = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
                            HStack {
                                Spacer()
                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                }
                            }
                            .padding([.horizontal, .top])

                            Spacer()

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

                // --- 2. RESULTS BLOCK ---
                LiveClassificationResultsView(
                    results: liveCameraManager.liveResults,
                    model: selectedModel
                )
                .frame(height: 220) // Fixed height for stability
                .padding()

                // --- 3. CAPTURE BUTTON ---
                Spacer()

                CaptureButton {
                    liveCameraManager.capturePhoto { image in
                        if let image = image {
                            Task { await cameraManager.classifyImage(image) }
                        }
                        dismiss()
                    }
                }
                .padding(.bottom)
            }
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

