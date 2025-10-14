//
//  HomeTabView.swift
//  swift-cam
//
//  Home tab with photo library selection and classification
//

import SwiftUI
import PhotosUI
import OSLog

/// The main view for the "Home" tab, focused on classifying images from the user's photo library.
///
/// This view allows a user to select an image, runs it through the currently selected
/// ML model, and displays the results. It serves as the primary interface for static
/// image analysis.
///
/// **UI Layout & States:**
/// The view has two primary states:
/// 1.  **Empty State:** A large, interactive button prompts the user to select a photo.
///     ```
///     ┌───────────────────────────┐
///     │         AI Vision         │
///     ├───────────────────────────┤
///     │                           │
///     │   [   Choose Photo    ]   │
///     │                           │
///     └───────────────────────────┘
///     ```
/// 2.  **Results State:** An image preview is shown with the classification results below.
///     ```
///     ┌───────────────────────────┐
///     │         AI Vision         │
///     ├───────────────────────────┤
///     │     [Image Preview]     │
///     ├───────────────────────────┤
///     │      [Result 1]         │
///     │      [Result 2]         │
///     └───────────────────────────┘
///     ```
///
/// **State Management:**
/// - Uses `HomeViewModel` as its primary source of truth for the selected image, classification results, and analysis state (loading, error).
/// - Receives `AppStateViewModel` to access global settings like `faceBlurringEnabled` and the current `blurStyle`.
/// - Uses local `@State` to manage the `PhotosPickerItem` selection.
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
                            // App Title with Premium Style and Status
                            HStack(alignment: .top, spacing: 16) {
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
                                
                                // Modern Status Badge - moved to the right
                                StatusTextView(viewModel: viewModel, selectedModel: appStateViewModel.selectedModel)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        }
                        .padding(.bottom, 32)
                        
                        // Main Content Area
                        VStack(spacing: 24) {
                            // Hero Section - Image Preview (no empty state)
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
                                // Large clickable photo library preview
                                PhotosPicker(
                                    selection: $selectedImage,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    VStack(spacing: 20) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 60, weight: .light))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.appAccent, .appSecondary],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        VStack(spacing: 8) {
                                            Text("Choose Photo")
                                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                            
                                            Text("Tap to select from library")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 280)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 28)
                                                .fill(.ultraThinMaterial)
                                            
                                            RoundedRectangle(cornerRadius: 28)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.12),
                                                            Color.white.opacity(0.04)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                            
                                            RoundedRectangle(cornerRadius: 28)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.3),
                                                            Color.white.opacity(0.1)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.5
                                                )
                                        }
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
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
                            
                            // Action Buttons Section (only show when image is loaded)
                            if viewModel.capturedImage != nil {
                                VStack(spacing: 16) {
                                    // Clear Button
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.clearImage()
                                        }
                                    }) {
                                        Label("Clear Image", systemImage: "arrow.counterclockwise")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 54)
                                            .background(
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(.ultraThinMaterial)
                                                    
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(
                                                            LinearGradient(
                                                                colors: [
                                                                    Color.red.opacity(0.3),
                                                                    Color.orange.opacity(0.2)
                                                                ],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                }
                                            )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                                .padding(.horizontal, 24)
                            }
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
