//
//  ContentView.swift
//  swift-cam
//
//  Main view - UI only, business logic in CameraViewModel
//

import SwiftUI
import PhotosUI
import OSLog

struct ContentView: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var showingLiveCamera = false
    @State private var selectedModel: MLModelType = .mobileNet
    
    var body: some View {
        NavigationView {
            ZStack {
                // Apple-style background gradient
                LinearGradient(
                    colors: [Color(.systemGray6), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        HeaderView(
                            viewModel: viewModel,
                            selectedModel: $selectedModel
                        )
                        
                        // Main Content Card
                        VStack(spacing: 24) {
                            // Image Display Area
                            ModernImagePreviewView(
                                image: viewModel.capturedImage,
                                isAnalyzing: viewModel.isAnalyzing
                            )
                            
                            // Classification Results
                            ModernClassificationResultsView(
                                results: viewModel.classificationResults,
                                isAnalyzing: viewModel.isAnalyzing,
                                error: viewModel.errorMessage
                            )
                            
                            // Action Buttons
                            ActionButtonsView(
                                viewModel: viewModel,
                                selectedImage: $selectedImage,
                                showingLiveCamera: $showingLiveCamera
                            )
                        }
                        .padding(.top, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: selectedImage) { _, newItem in
            Task {
                await handleImageSelection(newItem)
            }
        }
        .onAppear {
            ConditionalLogger.debug(Logger.ui, "📱 ContentView appeared - UI is ready")
        }
        .fullScreenCover(isPresented: $showingLiveCamera) {
            LiveCameraView(cameraManager: viewModel, selectedModel: selectedModel)
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

// MARK: - Header View
private struct HeaderView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var selectedModel: MLModelType
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Vision")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    StatusTextView(viewModel: viewModel, selectedModel: selectedModel)
                }
                
                Spacer()
                
                // Model Selector
                ModelSelectorView(viewModel: viewModel, selectedModel: $selectedModel)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
}

// MARK: - Status Text View
private struct StatusTextView: View {
    @ObservedObject var viewModel: CameraViewModel
    let selectedModel: MLModelType
    
    var body: some View {
        if viewModel.isLoadingModel {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                    .scaleEffect(0.7)
                Text("Loading \(viewModel.loadingModelName)...")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        } else if viewModel.isSwitchingModel {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(0.7)
                Text("Switching to \(selectedModel.displayName)...")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        } else if viewModel.isAnalyzing && viewModel.capturedImage != nil {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .scaleEffect(0.7)
                Text("Analyzing...")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.purple)
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("Using \(selectedModel.displayName)")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
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
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
            }
        }
    }
}

// MARK: - Model Selector View
private struct ModelSelectorView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var selectedModel: MLModelType
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(MLModelType.allCases) { model in
                Button(action: {
                    ConditionalLogger.debug(Logger.ui, "⚡ Instant model change to \(model.displayName)")
                    selectedModel = model
                    Task {
                        await viewModel.updateModel(to: model)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(selectedModel == model ? Color.blue : Color.gray.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        if viewModel.isSwitchingModel && selectedModel == model {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: model.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selectedModel == model ? .white : .secondary)
                        }
                    }
                }
                .disabled(viewModel.isSwitchingModel)
            }
        }
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
        .padding(.bottom, 40)
    }
}

#Preview {
    ContentView()
}

