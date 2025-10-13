//
//  LiveCameraView.swift
//  swift-cam
//
//  Live camera view with real-time ML classification
//

import SwiftUI
import OSLog

/// Live camera view with real-time object detection
///
/// This view provides the core camera experience with multiple intelligent features:
///
/// **Features:**
/// - Real-time ML classification (throttled to 0.5s intervals)
/// - Three capture modes:
///   1. Manual: Traditional photo capture
///   2. Assisted: Only allow capture when target object detected
///   3. Best Shot: Automatic capture over time period
/// - Object highlighting with custom rules
/// - Face privacy protection with blur options
/// - Multi-camera support (wide, ultra-wide, telephoto)
/// - Zoom controls
/// - Low-res preview mode for debugging
///
/// **Camera Modes:**
/// - Square mode: 1:1 aspect ratio with classification results below
/// - Full screen mode: Fills entire screen with overlay results
///
/// **UI Layout:**
/// ```
/// ┌─────────────────────┐
/// │  Camera Preview     │
/// │  (with highlighting)│
/// │                     │
/// ├─────────────────────┤
/// │ Classification      │
/// │ Results List        │
/// ├─────────────────────┤
/// │ [Best] [●] [Switch] │ ← Controls
/// └─────────────────────┘
/// ```
///
/// **Performance:**
/// - 60fps camera feed
/// - ML inference throttled to 2x per second
/// - Background processing queue for classification
/// - Main thread updates for UI
struct LiveCameraView: View {
    
    // MARK: - Dependencies
    
    /// Selected ML model for classification
    let selectedModel: MLModelType
    
    /// Global app state (settings, preferences)
    @ObservedObject var appStateViewModel: AppStateViewModel
    
    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss
    
    /// Live camera coordinator ViewModel
    @StateObject private var liveCameraManager: LiveCameraViewModel
    
    /// Optional custom dismiss handler for embedded mode
    let onCustomDismiss: (() -> Void)?

    // MARK: - Local State
    
    @State private var showLowResPreview = false
    @State private var showBestShotResults = false

    // MARK: - Initialization
    
    /// Initialize live camera view
    ///
    /// - Parameters:
    ///   - selectedModel: ML model to use for classification
    ///   - appStateViewModel: Global app state
    ///   - liveCameraManager: Camera manager (can inject for testing)
    ///   - onCustomDismiss: Optional custom dismiss handler
    init(selectedModel: MLModelType, appStateViewModel: AppStateViewModel, liveCameraManager: LiveCameraViewModel = LiveCameraViewModel(), onCustomDismiss: (() -> Void)? = nil) {
        self.selectedModel = selectedModel
        self.appStateViewModel = appStateViewModel
        _liveCameraManager = StateObject(wrappedValue: liveCameraManager)
        self.onCustomDismiss = onCustomDismiss
    }
    
    // MARK: - Computed Properties
    
    /// Whether to use full screen or square camera mode
    private var fullScreenCamera: Bool {
        appStateViewModel.fullScreenCamera
    }
    
    // MARK: - Actions
    
    /// Handle view dismissal (custom or environment)
    private func handleDismiss() {
        if let onCustomDismiss = onCustomDismiss {
            onCustomDismiss()
        } else {
            dismiss()
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if fullScreenCamera {
                fullScreenView
            } else {
                squareView
            }
        }
        .sheet(isPresented: $showBestShotResults) {
            if !liveCameraManager.topCandidates.isEmpty {
                BestShotResultsView(candidates: liveCameraManager.topCandidates) {
                    liveCameraManager.topCandidates.removeAll()
                    showBestShotResults = false
                }
            }
        }
        .onChange(of: liveCameraManager.topCandidates) { _, newCandidates in
            if !newCandidates.isEmpty {
                showBestShotResults = true
            }
        }
        .onAppear {
            liveCameraManager.updateModel(to: selectedModel)
            liveCameraManager.faceBlurringEnabled = appStateViewModel.faceBlurringEnabled
            liveCameraManager.blurStyle = appStateViewModel.blurStyle
            liveCameraManager.highlightRules = appStateViewModel.highlightRules // Set initial rules
            liveCameraManager.bestShotTargetLabel = appStateViewModel.bestShotTargetLabel // Set initial target
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
        .onChange(of: appStateViewModel.highlightRules) { _, newRules in
            liveCameraManager.highlightRules = newRules
        }
        .onChange(of: appStateViewModel.bestShotTargetLabel) { _, newLabel in
            liveCameraManager.bestShotTargetLabel = newLabel
        }
    }

    // MARK: - Full Screen View
    @ViewBuilder
    private var fullScreenView: some View {
        ZStack {
            // Camera Preview Layer
            CameraPreviewView(session: liveCameraManager.session)
                .border(liveCameraManager.shouldHighlight ? Color.green : Color.clear, width: 5)
                .ignoresSafeArea()

            // Overlays
            countdownOverlay
            lowResPreviewOverlay
            saveConfirmationOverlay

            // UI Controls
            VStack {
                Spacer()
                LiveClassificationResultsView(results: liveCameraManager.liveResults, model: selectedModel)
                    .frame(height: 180)
                    .padding(.horizontal)
                
                bottomControls
                    .padding(.bottom, 40)
            }
            .padding(.bottom, 40)
            .background(bottomGradient)
        }
    }

    // MARK: - Square View
    @ViewBuilder
    private var squareView: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    CameraPreviewView(session: liveCameraManager.session)
                        .border(liveCameraManager.shouldHighlight ? Color.green : Color.clear, width: 5)
                        .clipShape(Rectangle())

                    countdownOverlay
                    lowResPreviewOverlay
                    saveConfirmationOverlay
                    
                    VStack {
                        Spacer()
                        squareViewControls
                    }
                }
            }
            .aspectRatio(1.0, contentMode: .fit)

            LiveClassificationResultsView(results: liveCameraManager.liveResults, model: selectedModel)
                .frame(height: 180)
                .padding()

            Spacer()
            
            bottomControls
                .padding(.bottom, 20)
        }
    }

    // MARK: - Shared UI Components
    @ViewBuilder
    private var bottomControls: some View {
        HStack(spacing: 60) {
            // Best Shot Button
            Button(action: { 
                if liveCameraManager.isBestShotSequenceActive {
                    liveCameraManager.stopBestShotSequence()
                } else {
                    liveCameraManager.startBestShotSequence(duration: appStateViewModel.bestShotDuration)
                }
            }) {
                Image(systemName: liveCameraManager.isBestShotSequenceActive ? "xmark" : "timer")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(liveCameraManager.isBestShotSequenceActive ? .yellow : .white)
            }
            .padding(20)
            .background(Color.white.opacity(0.2))
            .clipShape(Circle())

            // Main Capture Button
            CaptureButton {
                liveCameraManager.capturePhotoAndSave()
            }
            .disabled(appStateViewModel.isAssistedCaptureEnabled && !liveCameraManager.shouldHighlight)
            .opacity((appStateViewModel.isAssistedCaptureEnabled && !liveCameraManager.shouldHighlight) ? 0.4 : 1.0)

            // Switch Camera Button (or other right-side control)
            Button(action: { liveCameraManager.switchCamera() }) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(Color.white.opacity(0.2))
            .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var squareViewControls: some View {
        HStack {
            ZoomControlView(manager: liveCameraManager)
            Spacer()
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
        }
        .padding()
    }

    @ViewBuilder
    private var countdownOverlay: some View {
        if liveCameraManager.isBestShotSequenceActive {
            ZStack {
                Color.black.opacity(0.5).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("\(Int(liveCameraManager.bestShotCountdown))")
                        .font(.system(size: 80, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    VStack {
                        Text("Looking for: \(appStateViewModel.bestShotTargetLabel.capitalized)")
                        Text("Candidates found: \(liveCameraManager.bestShotCandidateCount)")
                    }
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var lowResPreviewOverlay: some View {
        if showLowResPreview, let image = liveCameraManager.lowResPreviewImage {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .transition(.opacity)
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var saveConfirmationOverlay: some View {
        if liveCameraManager.showSaveConfirmation {
            VStack {
                Spacer()
                Text("Saved to Photos")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                Spacer()
                    .frame(height: 150)
            }
            .animation(.spring(), value: liveCameraManager.showSaveConfirmation)
        }
    }

    private var bottomGradient: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#if DEBUG
class MockHomeViewModel: HomeViewModel {}

class MockLiveCameraViewModelForPreview: LiveCameraViewModel {
    override func startSession() {
        // Do nothing to prevent camera access in preview
    }
}

#Preview {
    LiveCameraView(selectedModel: .mobileNet, appStateViewModel: AppStateViewModel(), liveCameraManager: MockLiveCameraViewModelForPreview())
}
#endif

