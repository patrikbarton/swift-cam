//
//  SettingsTabView.swift
//  swift-cam
//
//  Settings tab with comprehensive app configuration
//

import SwiftUI

/// Settings tab featuring ML model selection, camera settings, and system info
///
/// Provides a comprehensive settings interface organized into sections:
///
/// **Sections:**
/// 1. ML Model Selection
///    - Choose between MobileNet, ResNet, FastViT
///    - Shows model descriptions and status
///    - Instant switching (models are cached)
///
/// 2. Camera Settings
///    - Full screen camera toggle
///    - Assisted capture mode
///    - Face privacy protection
///    - Best Shot duration slider
///    - Best Shot target label
///
/// 3. Highlight Settings
///    - Configure which objects to highlight
///    - Set confidence thresholds per object
///
/// 4. Privacy Settings (conditional)
///    - Blur style selection (Gaussian, Pixelated, Black Box)
///    - Only shown when face blurring is enabled
///
/// 5. System Info
///    - Current compute unit (Neural Engine, GPU, CPU)
///    - Verification status
///
/// 6. About
///    - App version and description
///
/// **UI Design:**
/// Uses "Liquid Glass" design language with:
/// - Gradient background
/// - Ultra-thin material cards
/// - Consistent spacing and padding
/// - Haptic feedback on interactions
///
/// **State Management:**
/// All settings are persisted via `AppStateViewModel` which
/// automatically saves to UserDefaults on change.
struct SettingsTabView: View {
    
    // MARK: - Dependencies
    
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var appStateViewModel: AppStateViewModel
    private let hapticManager = HapticManagerService.shared
    
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
                        
                        // Camera Settings Section
                        cameraSettingsSection
                        
                        // Highlight Settings Section
                        highlightSettingsSection

                        // Privacy Settings Section (only if face blurring enabled)
                        if appStateViewModel.faceBlurringEnabled {
                            privacySettingsSection
                        }
                        
                        // System Info Section
                        systemInfoSection
                        
                        // App Info Section
                        appInfoSection
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
                    title: "Face Privacy Protection",
                    description: "Automatically blur detected faces for privacy",
                    isOn: $appStateViewModel.faceBlurringEnabled,
                    color: .purple
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

    private var privacySettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy Style")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            Text("Choose how faces are obscured")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(BlurStyle.allCases, id: \.self) { style in
                    BlurStyleRow(
                        style: style,
                        isSelected: appStateViewModel.blurStyle == style
                    ) {
                        appStateViewModel.blurStyle = style
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
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
