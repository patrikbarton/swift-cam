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
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var selectedModel: MLModelType = .mobileNet
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Left Tab - Home (Photo Library & Results)
            HomeTabView(viewModel: cameraViewModel, selectedModel: $selectedModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Middle Tab - Camera (Auto-open Live Camera)
            CameraTabView(viewModel: cameraViewModel, selectedModel: selectedModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(1)
            
            // Right Tab - Settings (with Model Selector)
            SettingsTabView(viewModel: cameraViewModel, selectedModel: $selectedModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(.blue)
        .preferredColorScheme(.dark) // Liquid Glass looks best in dark mode
    }
}

// MARK: - Home Tab View (Photo Library & Results)
struct HomeTabView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var selectedModel: MLModelType
    @State private var selectedImage: PhotosPickerItem? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid Glass background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.4), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("AI Vision")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            StatusTextView(viewModel: viewModel, selectedModel: selectedModel)
                        }
                        
                        // Image Preview
                        ModernImagePreviewView(
                            image: viewModel.capturedImage,
                            isAnalyzing: viewModel.isAnalyzing
                        )
                        .padding(.horizontal, 24)
                        
                        // Classification Results
                        ModernClassificationResultsView(
                            results: viewModel.classificationResults,
                            isAnalyzing: viewModel.isAnalyzing,
                            error: viewModel.errorMessage
                        )
                        .padding(.horizontal, 24)
                        
                        // Photo Library Button
                        VStack(spacing: 12) {
                            PhotosPicker(
                                selection: $selectedImage,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                AppleStyleButton(
                                    title: "Photo Library",
                                    subtitle: "Choose from your photos",
                                    icon: "photo.on.rectangle.angled",
                                    style: .primary
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(viewModel.isLoadingModel || viewModel.isAnalyzing || viewModel.isSwitchingModel)
                            
                            // Clear Button (only when needed)
                            if viewModel.capturedImage != nil {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.clearImage()
                                    }
                                }) {
                                    AppleStyleButton(
                                        title: "Clear Image",
                                        subtitle: "Start over",
                                        icon: "arrow.counterclockwise",
                                        style: .secondary
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
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
        .alert("Unable to Process", isPresented: .constant(viewModel.errorMessage != nil)) {
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
                    await viewModel.classifyImage(image)
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
    @ObservedObject var viewModel: CameraViewModel
    let selectedModel: MLModelType
    @Binding var selectedTab: Int
    @State private var showingLiveCamera = false
    
    var body: some View {
        ZStack {
            // Liquid Glass background
            LinearGradient(
                colors: [.cyan.opacity(0.4), .blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Camera Icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Live Camera")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Opening camera...")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
        }
        .onAppear {
            // Automatically open camera when tab is selected
            showingLiveCamera = true
        }
        .fullScreenCover(isPresented: $showingLiveCamera, onDismiss: {
            // When camera is dismissed, go back to Home tab
            selectedTab = 0
        }) {
            LiveCameraView(cameraManager: viewModel, selectedModel: selectedModel)
        }
    }
}

// MARK: - Settings Tab View
struct SettingsTabView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var selectedModel: MLModelType
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid Glass background
                LinearGradient(
                    colors: [.purple.opacity(0.4), .pink.opacity(0.3)],
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
                                        colors: [.purple, .pink],
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
                                        isSelected: selectedModel == model,
                                        viewModel: viewModel
                                    ) {
                                        selectedModel = model
                                        Task {
                                            await viewModel.updateModel(to: model)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
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
    @ObservedObject var viewModel: CameraViewModel
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
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
                        .foregroundStyle(.blue)
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

// MARK: - Supporting Views (from original ContentView)

// MARK: - Status Text View
private struct StatusTextView: View {
    @ObservedObject var viewModel: CameraViewModel
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
    @ObservedObject var viewModel: CameraViewModel
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
                                .fill(selectedModel == model ? Color.blue : Color.white.opacity(0.2))
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

// MARK: - Action Buttons View
private struct ActionButtonsView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var selectedImage: PhotosPickerItem?
    @Binding var showingLiveCamera: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Primary Action - Live Camera
            Button(action: {
                showingLiveCamera = true
            }) {
                AppleStyleButton(
                    title: "Live Camera",
                    subtitle: "Real-time object detection",
                    icon: "viewfinder",
                    style: .primary
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Secondary Action - Photo Library
            PhotosPicker(
                selection: $selectedImage,
                matching: .images,
                photoLibrary: .shared()
            ) {
                AppleStyleButton(
                    title: "Photo Library",
                    subtitle: "Choose from your photos",
                    icon: "photo.on.rectangle.angled",
                    style: .secondary
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isLoadingModel || viewModel.isAnalyzing || viewModel.isSwitchingModel)
            
            // Tertiary Action - Clear (only when needed)
            if viewModel.capturedImage != nil {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.clearImage()
                    }
                }) {
                    AppleStyleButton(
                        title: "Clear Image",
                        subtitle: "Start over",
                        icon: "arrow.counterclockwise",
                        style: .tertiary
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    ContentView()
}
