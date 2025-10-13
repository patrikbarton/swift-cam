//
//  ContentView.swift
//  swift-cam
//
//  Main view with Liquid Glass Tab Bar
//

import SwiftUI
import PhotosUI
import OSLog

struct ContentView: View {
    @State private var selectedTab = 0 // Default to Home
    @StateObject private var cameraViewModel = HomeViewModel()
    @StateObject private var appStateViewModel = AppStateViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Left Tab - Home (Photo Library & Results)
            HomeTabView(viewModel: cameraViewModel, appStateViewModel: appStateViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Middle Tab - Camera (Auto-open Live Camera)
            CameraTabView(viewModel: cameraViewModel, selectedTab: $selectedTab, appStateViewModel: appStateViewModel)
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(1)
            
            // Right Tab - Settings (with Model Selector)
            SettingsTabView(viewModel: cameraViewModel, appStateViewModel: appStateViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(.appAccent)
        .preferredColorScheme(.dark) // Liquid Glass looks best in dark mode
    }
}

// MARK: - Home Tab View (Photo Library & Results)
struct HomeTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var appStateViewModel: AppStateViewModel
    @State private var selectedImage: PhotosPickerItem? = nil
    
    private var showErrorAlert: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    colors: Color.appPrimaryGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Floating Header
                        VStack(spacing: 16) {
                            // App Title with Premium Style
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI Vision")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.white, .white.opacity(0.9)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    Text("Intelligent Recognition")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            
                            // Modern Status Badge
                            HStack {
                                StatusTextView(viewModel: viewModel, selectedModel: appStateViewModel.selectedModel)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 32)
                        
                        // Main Content Area
                        VStack(spacing: 24) {
                            // Hero Section - Image Preview or Empty State
                            if viewModel.capturedImage != nil || viewModel.isAnalyzing {
                                ModernImagePreviewView(
                                    image: viewModel.capturedImage,
                                    isAnalyzing: viewModel.isAnalyzing,
                                    onClear: {
                                        viewModel.clearImage()
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                            } else {
                                // Premium Empty State
                                PremiumEmptyStateView()
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Classification Results (if available)
                            if !viewModel.classificationResults.isEmpty || viewModel.isAnalyzing {
                                ModernClassificationResultsView(
                                    results: viewModel.classificationResults,
                                    isAnalyzing: viewModel.isAnalyzing,
                                    error: viewModel.errorMessage
                                )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            // Action Buttons Section
                            VStack(spacing: 16) {
                                // Photo Library Button
                                PhotosPicker(
                                    selection: $selectedImage,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    HStack(spacing: 16) {
                                        // Icon Container
                                        ZStack {
                                            Circle()
                                                .fill(.white.opacity(0.15))
                                                .frame(width: 56, height: 56)
                                            
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundStyle(.white)
                                        }
                                        
                                        // Text Content
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Photo Library")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)
                                            
                                            Text("Choose from your photos")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        // Chevron
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    .padding(20)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 24)
                                                .fill(.ultraThinMaterial)
                                            
                                            RoundedRectangle(cornerRadius: 24)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.appAccent.opacity(0.3),
                                                            Color.appSecondary.opacity(0.2)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                            
                                            RoundedRectangle(cornerRadius: 24)
                                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                        }
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .disabled(viewModel.isLoadingModel || viewModel.isAnalyzing || viewModel.isSwitchingModel)
                                .opacity((viewModel.isLoadingModel || viewModel.isAnalyzing || viewModel.isSwitchingModel) ? 0.5 : 1)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            
                            // Bottom Spacer
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: selectedImage) { _, newItem in
            Task {
                await handleImageSelection(newItem)
            }
        }
        .alert("Unable to Process", isPresented: showErrorAlert) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func handleImageSelection(_ newItem: PhotosPickerItem?) async {
        guard let newItem = newItem else { return }
        
        viewModel.errorMessage = nil
        
        do {
            if let data = try? await newItem.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    await viewModel.classifyImage(image, applyFaceBlur: appStateViewModel.faceBlurringEnabled, blurStyle: appStateViewModel.blurStyle)
                    return
                } else {
                    throw ImageLoadingError.corruptedData
                }
            } else {
                throw ImageLoadingError.unsupportedFormat
            }
            
        } catch let error as ImageLoadingError {
            Logger.image.error("Image loading failed: \(error.localizedDescription)")
            viewModel.errorMessage = error.localizedDescription
        } catch {
            Logger.image.error("Image loading failed with unknown error: \(error.localizedDescription)")
            viewModel.errorMessage = ImageLoadingError.accessDenied.localizedDescription
        }
        
        selectedImage = nil
    }
}

// MARK: - Premium Empty State View
struct PremiumEmptyStateView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated Icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.3 - Double(index) * 0.1),
                                    Color.appSecondary.opacity(0.2 - Double(index) * 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 140 + CGFloat(index) * 30, height: 140 + CGFloat(index) * 30)
                        .opacity(isAnimating ? 0.0 : 0.5)
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .animation(
                            .easeOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }
                
                // Main icon container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.4),
                                    Color.appSecondary.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 130, height: 130)
                    
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse.byLayer, options: .repeating, value: isAnimating)
                }
                .shadow(color: Color.appAccent.opacity(0.3), radius: 30, y: 15)
            }
            .padding(.vertical, 20)
            
            // Text Content
            VStack(spacing: 12) {
                Text("Ready to Analyze")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Select an image to see intelligent\nrecognition results")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 32)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.01)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 32)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            }
        )
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.1), radius: 30, y: 15)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Feature Card Component
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Camera Tab View (Auto-open Live Camera)
struct CameraTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedTab: Int
    @ObservedObject var appStateViewModel: AppStateViewModel
    @StateObject private var liveCameraManager = LiveCameraViewModel()
    
    var body: some View {
        // Camera directly embedded in tab - Tab Bar stays visible!
        LiveCameraView(
            cameraManager: viewModel, 
            selectedModel: appStateViewModel.selectedModel, 
            appStateViewModel: appStateViewModel, // Pass ViewModel instead of value
            liveCameraManager: liveCameraManager,
            onCustomDismiss: {
                // When back button pressed, go back to Home tab
                selectedTab = 0
            }
        )
        .ignoresSafeArea(.all, edges: .top) // Full screen camera but tab bar visible
    }
}

// MARK: - Settings Tab View
struct SettingsTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var appStateViewModel: AppStateViewModel
    
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
                                        appStateViewModel.selectedModel = model
                                        Task {
                                            await viewModel.updateModel(to: model)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Camera Settings Section
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

                                // Best Shot Duration Slider
                                VStack(spacing: 12) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color.cyan.opacity(0.2))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "timer")
                                                .font(.system(size: 22))
                                                .foregroundStyle(Color.cyan)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Best Shot Duration")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(.white)
                                            
                                            Text("Duration for the auto-capture sequence")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.white.opacity(0.6))
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                        Text("\(Int(appStateViewModel.bestShotDuration))s")
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(.white)
                                    }
                                    Slider(value: $appStateViewModel.bestShotDuration, in: 3...30, step: 1)
                                        .tint(.cyan)
                                }
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                                NavigationLink(destination: BestShotSettingsView(targetLabel: $appStateViewModel.bestShotTargetLabel, modelLabels: viewModel.modelLabels)) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange.opacity(0.2))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "scope")
                                                .font(.system(size: 22))
                                                .foregroundStyle(Color.orange)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Best Shot Target")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(.white)
                                            
                                            Text(appStateViewModel.bestShotTargetLabel.isEmpty ? "None" : appStateViewModel.bestShotTargetLabel.capitalized)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.white.opacity(0.6))
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    .padding(16)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Highlight Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Highlight Settings")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                NavigationLink(destination: HighlightSettingsView(highlightRules: $appStateViewModel.highlightRules, modelLabels: viewModel.modelLabels)) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.appAccent.opacity(0.2))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 22))
                                                .foregroundStyle(Color.appAccent)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Highlight Rules")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(.white)
                                            
                                            Text("Configure objects to highlight in the camera")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.white.opacity(0.6))
                                                .lineLimit(2)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    .padding(16)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        // Privacy Settings Section (Blur Style Picker - only show if face blurring is enabled)
                        if appStateViewModel.faceBlurringEnabled {
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
                        
                        // System Info Section
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
                        
                        // App Info Section
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
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Model Setting Row Component
struct ModelSettingRow: View {
    let model: MLModelType
    let isSelected: Bool
    @ObservedObject var viewModel: HomeViewModel
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.appAccent : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    if viewModel.isSwitchingModel && isSelected {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: model.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(isSelected ? .white : .gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(modelDescription(for: model))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appAccent)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(viewModel.isSwitchingModel)
    }
    
    private func modelDescription(for model: MLModelType) -> String {
        switch model {
        case .mobileNet:
            return "Fast and efficient, great for real-time detection"
        case .resnet50:
            return "Higher accuracy, balanced performance"
        case .fastViT:
            return "State-of-the-art Vision Transformer model"
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Camera Setting Toggle Row Component
struct CameraSettingToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Blur Style Row Component
struct BlurStyleRow: View {
    let style: BlurStyle
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: iconForStyle(style))
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(style.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.purple)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private func iconForStyle(_ style: BlurStyle) -> String {
        switch style {
        case .gaussian:
            return "eye.slash.fill"
        case .pixelated:
            return "square.grid.3x3.fill"
        case .blackBox:
            return "rectangle.fill"
        }
    }
}

// MARK: - Supporting Views (from original ContentView)

// MARK: - Status Text View
private struct StatusTextView: View {
    @ObservedObject var viewModel: HomeViewModel
    let selectedModel: MLModelType
    
    var body: some View {
        if viewModel.isLoadingModel {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                Text("Loading \(viewModel.loadingModelName)...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        } else if viewModel.isSwitchingModel {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                Text("Switching to \(selectedModel.displayName)...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        } else if viewModel.isAnalyzing && viewModel.capturedImage != nil {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                Text("Analyzing...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        } else {
            VStack(spacing: 4) {
                Text("Using \(selectedModel.displayName)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                if !viewModel.currentComputeUnit.isEmpty {
                    HStack(spacing: 4) {
                        if viewModel.isComputeUnitVerified {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                        
                        Text("• \(viewModel.currentComputeUnit)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Model Selector View
private struct ModelSelectorView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedModel: MLModelType
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(MLModelType.allCases) { model in
                Button(action: {
                    ConditionalLogger.debug(Logger.ui, "⚡ Model change to \(model.displayName)")
                    selectedModel = model
                    Task {
                        await viewModel.updateModel(to: model)
                    }
                }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(selectedModel == model ? Color.appAccent : Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            if viewModel.isSwitchingModel && selectedModel == model {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: model.icon)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(selectedModel == model ? .white : .white.opacity(0.6))
                            }
                        }
                        
                        Text(model.shortName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .disabled(viewModel.isSwitchingModel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ContentView()
}
