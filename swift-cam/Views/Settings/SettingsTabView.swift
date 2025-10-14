//
//  SettingsTabView.swift
//  swift-cam
//
//  The main view for the "Settings" tab, providing a comprehensive list of app configurations.
//

import SwiftUI

/// A view that presents a list of all user-configurable settings for the application.
///
/// This view acts as the central hub for tweaking ML models, camera behavior, privacy
/// settings, and more. It is composed of multiple sub-sections, each handling a
/// specific domain of configuration.
///
/// **UI Layout:**
/// ```
/// ┌───────────────────────────┐
/// │         [Header]          │
/// │ ┌───────────────────────┐ │
/// │ │ [ML Model Selection]  │ │
/// │ ├───────────────────────┤ │
/// │ │ [Camera Modes]        │ │
/// │ ├───────────────────────┤ │
/// │ │ [Best Shot Settings]  │ │
/// │ ├───────────────────────┤ │
/// │ │ [Privacy Settings]    │ │
/// │ └───────────────────────┘ │
/// │           ...             │
/// └───────────────────────────┘
/// ```
///
/// **State Management:**
/// - Binds directly to properties on the shared `AppStateViewModel` for most settings (toggles, navigation).
/// - Uses local `@State` variables for sliders (`localBestShotDuration`, `localBestShotConfidence`) to provide
///   live UI feedback during dragging, syncing the final value back to `AppStateViewModel` on change.
struct SettingsTabView: View {
    
    // MARK: - Dependencies
    
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var appStateViewModel: AppStateViewModel
    private let hapticManager = HapticManagerService.shared
    
    // MARK: - Local State for Live Slider Updates
    
    @State private var localBestShotDuration: Double
    @State private var localBestShotConfidence: Double

    // MARK: - Initialization
    
    init(viewModel: HomeViewModel, appStateViewModel: AppStateViewModel) {
        self.viewModel = viewModel
        self.appStateViewModel = appStateViewModel
        // Initialize local state from the view model to sync them initially
        _localBestShotDuration = State(initialValue: appStateViewModel.bestShotDuration)
        _localBestShotConfidence = State(initialValue: appStateViewModel.bestShotConfidenceThreshold)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid Glass background
                LinearGradient(
                    colors: Color.appMixedGradient2,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.appAccent, .appSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.top, 40)
                            
                            Text("Settings")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        // Model Selection Section
                        modelSelectionSection
                        
                        // Camera Modes Section
                        cameraModesSection
                        
                        // Best Shot Settings Section
                        bestShotSettingsSection
                        
                        // Highlight Settings Section
                        highlightSettingsSection

                        // Privacy Settings Section
                        privacySettingsSection
                        
                        // System Info Section
                        systemInfoSection
                        
                        // App Info Section
                        appInfoSection
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: localBestShotDuration) { _, newValue in
                appStateViewModel.bestShotDuration = newValue
            }
            .onChange(of: localBestShotConfidence) { _, newValue in
                appStateViewModel.bestShotConfidenceThreshold = newValue
            }
        }
    }
    
    // MARK: - Sections
    
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ML Model Selection")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            Text("Choose the AI model for image classification")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(MLModelType.allCases) { model in
                    ModelSettingRow(
                        model: model,
                        isSelected: appStateViewModel.selectedModel == model,
                        viewModel: viewModel
                    ) {
                        hapticManager.impact(.light)
                        appStateViewModel.selectedModel = model
                        Task {
                            await viewModel.updateModel(to: model)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var cameraModesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Camera Modes")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            Text("Configure camera display and features")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                CameraSettingToggleRow(
                    icon: "viewfinder.rectangular",
                    title: "Full Screen Camera",
                    description: "Expand camera to full screen or keep it square",
                    isOn: $appStateViewModel.fullScreenCamera,
                    color: .appPrimary
                )

                CameraSettingToggleRow(
                    icon: "wand.and.stars",
                    title: "Assisted Capture",
                    description: "Only allow photo capture when a highlighted object is detected",
                    isOn: $appStateViewModel.isAssistedCaptureEnabled,
                    color: .yellow
                )
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var bestShotSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Best Shot Mode")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            Text("Auto-capture settings for best shot mode")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                BestShotDurationSlider(
                    icon: "timer",
                    title: "Best Shot Duration",
                    description: "Duration for the auto-capture sequence",
                    duration: $localBestShotDuration, // Bind to local state
                    color: .cyan
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.green)
                            .frame(width: 30)
                        Text("Confidence Threshold")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Minimum confidence to trigger auto-capture")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.leading, 30)

                    Slider(value: $localBestShotConfidence, in: 0.0...1.0) { // Bind to local state
                        Text("Confidence")
                    } minimumValueLabel: {
                        Text("0%")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    } maximumValueLabel: {
                        Text("100%")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .tint(.green)
                    
                    Text("\(Int(localBestShotConfidence * 100))%") // Read from local state
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .center)

                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                NavigationLink(destination: BestShotSettingsView(targetLabel: $appStateViewModel.bestShotTargetLabel, modelLabels: viewModel.modelLabels)) {
                    SettingsNavigationRow(
                        icon: "scope",
                        iconColor: .orange,
                        title: "Best Shot Target",
                        subtitle: appStateViewModel.bestShotTargetLabel.isEmpty ? "None" : appStateViewModel.bestShotTargetLabel.capitalized,
                        destination: BestShotSettingsView(targetLabel: $appStateViewModel.bestShotTargetLabel, modelLabels: viewModel.modelLabels)
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var privacySettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy Settings")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            Text("Control face blurring and location data")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                CameraSettingToggleRow(
                    icon: "face.smiling",
                    title: "Blur Faces in Photos",
                    description: "Blur faces in captured photos (saved to library)",
                    isOn: $appStateViewModel.faceBlurringEnabled,
                    color: .purple
                )
                
                CameraSettingToggleRow(
                    icon: "eye.slash",
                    title: "Blur Faces in Live Preview",
                    description: "Show blurred preview on screen (may affect performance)",
                    isOn: $appStateViewModel.livePreviewBlurEnabled,
                    color: .indigo
                )
                
                // Blur style selection (only if any face blurring enabled)
                if appStateViewModel.faceBlurringEnabled || appStateViewModel.livePreviewBlurEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Blur Style")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        ForEach(BlurStyle.allCases, id: \.self) { style in
                            BlurStyleRow(
                                style: style,
                                isSelected: appStateViewModel.blurStyle == style
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    appStateViewModel.blurStyle = style
                                }
                            }
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Divider()
                    .background(.white.opacity(0.2))
                    .padding(.vertical, 4)
                
                CameraSettingToggleRow(
                    icon: "location.fill",
                    title: "Include Location",
                    description: "Embed GPS coordinates in saved photos",
                    isOn: $appStateViewModel.includeLocationMetadata,
                    color: .green
                )
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var cameraSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Camera Settings")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            Text("Customize your camera experience")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                CameraSettingToggleRow(
                    icon: "viewfinder.rectangular",
                    title: "Full Screen Camera",
                    description: "Expand camera to full screen or keep it square",
                    isOn: $appStateViewModel.fullScreenCamera,
                    color: .appPrimary
                )

                CameraSettingToggleRow(
                    icon: "wand.and.stars",
                    title: "Assisted Capture",
                    description: "Only allow photo capture when a highlighted object is detected",
                    isOn: $appStateViewModel.isAssistedCaptureEnabled,
                    color: .yellow
                )
                
                CameraSettingToggleRow(
                    icon: "face.smiling",
                    title: "Blur Faces in Photos",
                    description: "Blur faces in captured photos (saved to library)",
                    isOn: $appStateViewModel.faceBlurringEnabled,
                    color: .purple
                )
                
                CameraSettingToggleRow(
                    icon: "eye.slash",
                    title: "Blur Faces in Live Preview",
                    description: "Show blurred preview on screen (may affect performance)",
                    isOn: $appStateViewModel.livePreviewBlurEnabled,
                    color: .indigo
                )
                
                CameraSettingToggleRow(
                    icon: "location.fill",
                    title: "Include Location",
                    description: "Embed GPS coordinates in saved photos",
                    isOn: $appStateViewModel.includeLocationMetadata,
                    color: .green
                )

                BestShotDurationSlider(
                    icon: "timer",
                    title: "Best Shot Duration",
                    description: "Duration for the auto-capture sequence",
                    duration: $appStateViewModel.bestShotDuration,
                    color: .cyan
                )

                NavigationLink(destination: BestShotSettingsView(targetLabel: $appStateViewModel.bestShotTargetLabel, modelLabels: viewModel.modelLabels)) {
                    SettingsNavigationRow(
                        icon: "scope",
                        iconColor: .orange,
                        title: "Best Shot Target",
                        subtitle: appStateViewModel.bestShotTargetLabel.isEmpty ? "None" : appStateViewModel.bestShotTargetLabel.capitalized,
                        destination: BestShotSettingsView(targetLabel: $appStateViewModel.bestShotTargetLabel, modelLabels: viewModel.modelLabels)
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var highlightSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Highlight Settings")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            Text("Configure which objects to highlight in camera view")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                NavigationLink(destination: HighlightSettingsView(highlightRules: $appStateViewModel.highlightRules, modelLabels: viewModel.modelLabels)) {
                    SettingsNavigationRow(
                        icon: "sparkles",
                        iconColor: .appAccent,
                        title: "Highlight Rules",
                        subtitle: "Configure objects to highlight in the camera",
                        destination: HighlightSettingsView(highlightRules: $appStateViewModel.highlightRules, modelLabels: viewModel.modelLabels)
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Info")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "cpu.fill",
                    title: "Compute Unit",
                    value: viewModel.currentComputeUnit.isEmpty ? "Neural Engine" : viewModel.currentComputeUnit,
                    color: .orange
                )
                
                InfoRow(
                    icon: "checkmark.circle.fill",
                    title: "Status",
                    value: viewModel.isComputeUnitVerified ? "Verified" : "Checking...",
                    color: viewModel.isComputeUnitVerified ? .green : .yellow
                )
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Vision")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("A powerful real-time object detection app using CoreML and Vision framework.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                
                Divider()
                    .background(.white.opacity(0.3))
                
                HStack {
                    Text("Version")
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.white)
                }
                .font(.subheadline)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    SettingsTabView(viewModel: HomeViewModel(), appStateViewModel: AppStateViewModel())
}
