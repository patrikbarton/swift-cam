//
//  HomeTabView.swift
//  swift-cam
//
//  Home tab with photo library selection and classification
//

import SwiftUI
import PhotosUI
import OSLog

/// Home tab featuring photo library selection and ML classification results
///
/// This view provides the static image classification experience:
///
/// **Features:**
/// - Photo library image selection via PhotosPicker
/// - ML classification with selected model
/// - Face privacy protection (optional blur)
/// - Confidence-based result display
/// - Error handling with user-friendly alerts
///
/// **UI Flow:**
/// 1. User selects image from photo library
/// 2. Image loads and displays with loading indicator
/// 3. Classification runs in background
/// 4. Results appear below image, sorted by confidence
/// 5. Option to clear and select new image
///
/// **UI States:**
/// - Empty: Premium animated empty state
/// - Loading: Progress indicator with model name
/// - Results: Image preview + classification list
/// - Error: Alert with localized error message
///
/// **Integration:**
/// - Uses `HomeViewModel` for classification logic
/// - Accesses `AppStateViewModel` for global settings
/// - Respects face blurring preference
/// - Shows current model and compute unit
struct HomeTabView: View {
    
    // MARK: - Dependencies
    
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var appStateViewModel: AppStateViewModel
    
    // MARK: - Local State
    
    @State private var selectedImage: PhotosPickerItem? = nil
    
    // MARK: - Computed Properties
    
    /// Binding for error alert presentation
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
                                ImagePreviewView(
                                    image: viewModel.capturedImage,
                                    isAnalyzing: viewModel.isAnalyzing,
                                    onClear: {
                                        viewModel.clearImage()
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                            } else {
                                // Premium Empty State
                                EmptyStateView()
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Classification Results (if available)
                            if !viewModel.classificationResults.isEmpty || viewModel.isAnalyzing {
                                HomeClassificationResultsView(
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
    
    // MARK: - Private Methods
    
    // MARK: - Private Methods
    
    /// Handle image selection from PhotosPicker
    ///
    /// Loads image data, validates format, and triggers classification
    /// with optional face blurring based on user settings.
    ///
    /// - Parameter newItem: Selected photo picker item
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

// MARK: - Status Text View

/// Displays current model status and loading indicators
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

#Preview {
    HomeTabView(viewModel: HomeViewModel(), appStateViewModel: AppStateViewModel())
}
