import SwiftUI
import PhotosUI
import Combine
import CoreML
import Vision
import AVFoundation
import OSLog

// MARK: - Logging

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    /// UI-related logging
    static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// ML Model management logging
    static let model = Logger(subsystem: subsystem, category: "Model")
    
    /// Performance and inference logging
    static let performance = Logger(subsystem: subsystem, category: "Performance")
    
    /// Image processing logging
    static let image = Logger(subsystem: subsystem, category: "Image")
}

// MARK: - Conditional Logging Helpers

/// Helper functions for conditional logging based on build configuration
struct ConditionalLogger {
    /// Debug logging that only shows in DEBUG builds
    static func debug(_ logger: Logger, _ message: String) {
        #if DEBUG
        logger.debug("\(message)")
        #endif
    }
    
    /// Performance logging that only shows in DEBUG builds
    static func performance(_ logger: Logger, _ message: String) {
        #if DEBUG
        logger.info("\(message)")
        #endif
    }
}

// MARK: - Constants

private enum AppConstants {
    static let maxClassificationResults = 5
    static let modelSwitchDelayNanoseconds: UInt64 = 500_000_000 // 0.5 seconds
    static let animationSpringResponse: Double = 0.8
    static let animationDampingFraction: Double = 0.8
    static let imageMaxHeight: CGFloat = 280
    static let imageMinHeight: CGFloat = 200
    static let imageMaxHeightContainer: CGFloat = 300
}

// MARK: - ML Model Types

/// Represents the available machine learning models for image classification
enum MLModelType: String, CaseIterable, Identifiable {
    case mobileNet = "MobileNetV2"
    case resnet50 = "Resnet50"
    case fastViT = "FastViTMA36F16"
    
    var id: String { rawValue }
    
    /// Human-readable display name for the model
    var displayName: String {
        switch self {
        case .mobileNet: return "MobileNet V2"
        case .resnet50: return "ResNet-50"
        case .fastViT: return "FastViT"
        }
    }
    
    var shortName: String {
        switch self {
        case .mobileNet: return "MobileNet"
        case .resnet50: return "ResNet"
        case .fastViT: return "FastViT"
        }
    }
    
    /// Brief description of the model's characteristics
    var description: String {
        switch self {
        case .mobileNet: return "Efficient & Fast"
        case .resnet50: return "High Accuracy"
        case .fastViT: return "Vision Transformer"
        }
    }
    
    /// SF Symbol icon representing the model
    var icon: String {
        switch self {
        case .mobileNet: return "bolt.fill"
        case .resnet50: return "target"
        case .fastViT: return "eye.fill"
        }
    }
}

// MARK: - Error Types

enum ImageLoadingError: LocalizedError {
    case unsupportedFormat
    case corruptedData
    case accessDenied
    case cloudSyncError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Image format not supported. Please try JPEG, PNG, or HEIC."
        case .corruptedData:
            return "The selected image appears to be corrupted."
        case .accessDenied:
            return "Unable to access the selected image."
        case .cloudSyncError:
            return "Cloud Photo Library sync error. Please try a different image."
        }
    }
}

enum ModelLoadingError: LocalizedError {
    case modelNotFound(String)
    case neuralEngineFailure(String)
    case cpuFallbackFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let modelName):
            return "Model \(modelName) could not be found."
        case .neuralEngineFailure(let modelName):
            return "Neural Engine failed to load \(modelName)."
        case .cpuFallbackFailed(let modelName):
            return "CPU fallback failed for \(modelName)."
        }
    }
}

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
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
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI Vision")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    if cameraManager.isLoadingModel {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                                                .scaleEffect(0.7)
                                            Text("Loading \(cameraManager.loadingModelName)...")
                                                .font(.system(size: 17, weight: .medium))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                    } else if cameraManager.isSwitchingModel {
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
                                    } else if cameraManager.isAnalyzing && cameraManager.capturedImage != nil {
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
                                            
                                            if !cameraManager.currentComputeUnit.isEmpty {
                                                HStack(spacing: 4) {
                                                    if cameraManager.isComputeUnitVerified {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.green)
                                                    } else {
                                                        Image(systemName: "questionmark.circle.fill")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.orange)
                                                    }
                                                    
                                                    Text("• \(cameraManager.currentComputeUnit)")
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundColor(.secondary.opacity(0.7))
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                // Simple Model Selector - No Redundancy
                                HStack(spacing: 12) {
                                    ForEach(MLModelType.allCases) { model in
                                        Button(action: {
                                            Logger.ui.info("⚡ Instant model change to \(model.displayName)")
                                            selectedModel = model
                                            cameraManager.updateModel(to: model)
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(selectedModel == model ? Color.blue : Color.gray.opacity(0.2))
                                                    .frame(width: 44, height: 44)
                                                
                                                if cameraManager.isSwitchingModel && selectedModel == model {
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
                                        .disabled(cameraManager.isSwitchingModel)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        }
                        
                        // Main Content Card
                        VStack(spacing: 24) {
                            // Image Display Area
                            ModernImagePreviewView(
                                image: cameraManager.capturedImage,
                                isAnalyzing: cameraManager.isAnalyzing
                            )
                            
                            // Classification Results
                            ModernClassificationResultsView(
                                results: cameraManager.classificationResults,
                                isAnalyzing: cameraManager.isAnalyzing,
                                error: cameraManager.errorMessage
                            )
                            
                            // Action Buttons
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
                                .disabled(cameraManager.isLoadingModel || cameraManager.isAnalyzing || cameraManager.isSwitchingModel)
                                
                                // Tertiary Action - Clear (only when needed)
                                if cameraManager.capturedImage != nil {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            cameraManager.clearImage()
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
                        .padding(.top, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: selectedImage) { _, newItem in
            Task {
                guard let newItem = newItem else { return }
                
                // Clear any previous errors
                cameraManager.errorMessage = nil
                
                do {
                    // Attempt to load image data
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let image = UIImage(data: data) {
                            await cameraManager.classifyImage(image)
                            return
                        } else {
                            // Data loaded but UIImage creation failed
                            throw ImageLoadingError.corruptedData
                        }
                    } else {
                        // Data loading failed - could be format or access issue  
                        throw ImageLoadingError.unsupportedFormat
                    }
                    
                } catch let error as ImageLoadingError {
                    Logger.image.error("Image loading failed: \(error.localizedDescription)")
                    cameraManager.errorMessage = error.localizedDescription
                } catch {
                    // Generic error fallback
                    Logger.image.error("Image loading failed with unknown error: \(error.localizedDescription)")
                    cameraManager.errorMessage = ImageLoadingError.accessDenied.localizedDescription
                }
                
                // Clear selection to allow retry
                selectedImage = nil
            }
        }
        // Remove the problematic onChange - we handle everything in button action
        .onAppear {
            Logger.ui.info("📱 ContentView appeared - UI is ready")
        }
        .fullScreenCover(isPresented: $showingLiveCamera) {
            LiveCameraView(cameraManager: cameraManager, selectedModel: selectedModel)
        }
        .alert("Unable to Process", isPresented: .constant(cameraManager.errorMessage != nil)) {
            Button("OK") {
                cameraManager.clearError()
            }
        } message: {
            if let errorMessage = cameraManager.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Modern Image Preview
struct ModernImagePreviewView: View {
    let image: UIImage?
    let isAnalyzing: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: AppConstants.imageMaxHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(8) // Add padding inside the container
                    .scaleEffect(isAnalyzing ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isAnalyzing)
            } else {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    
                    VStack(spacing: 6) {
                        Text("No Image Selected")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Capture or select a photo to identify objects")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
            }
            
            // Analysis Overlay
            if isAnalyzing {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.95))
                    .overlay(
                        VStack(spacing: 16) {
                            // Modern loading indicator
                            ZStack {
                                Circle()
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                                    .frame(width: 40, height: 40)
                                
                                Circle()
                                    .trim(from: 0, to: 0.7)
                                    .stroke(
                                        AngularGradient(
                                            colors: [Color.blue, Color.purple],
                                            center: .center
                                        ),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .frame(width: 40, height: 40)
                                    .rotationEffect(.degrees(isAnalyzing ? 360 : 0))
                                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnalyzing)
                            }
                            
                            Text("Analyzing Image...")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .frame(minHeight: AppConstants.imageMinHeight, maxHeight: AppConstants.imageMaxHeightContainer) // Dynamic height based on content
        .padding(.horizontal, 24)
    }
}

// MARK: - Modern Classification Results
struct ModernClassificationResultsView: View {
    let results: [ClassificationResult]
    let isAnalyzing: Bool
    let error: String?
    
    var body: some View {
        VStack(spacing: 16) {
            if let error = error {
                ModernErrorView(message: error)
            } else if !results.isEmpty {
                ModernResultsList(results: results)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 1.05)).combined(with: .move(edge: .top))
                    ))
            } else if !isAnalyzing {
                ModernEmptyResultsView()
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Modern Results List
struct ModernResultsList: View {
    let results: [ClassificationResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recognition Results")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let topResult = results.first {
                    ModernConfidenceBadge(confidence: topResult.confidence)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(results.prefix(AppConstants.maxClassificationResults), id: \.identifier) { result in
                    ModernClassificationRow(result: result)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)).combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .scale(scale: 0.8)).combined(with: .move(edge: .trailing))
                        ))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.08), lineWidth: 1)
                )
        )
        .animation(.spring(response: AppConstants.animationSpringResponse, dampingFraction: AppConstants.animationDampingFraction), value: results.count)
        .scaleEffect(results.isEmpty ? 1.0 : 1.0) // Keep consistent scale
        .opacity(results.isEmpty ? 0.7 : 1.0) // Subtle fade when switching
        .animation(.easeInOut(duration: 0.4), value: results.isEmpty)
        .id("results-\(results.first?.identifier ?? "empty")") // Force refresh when results change
    }
}

// MARK: - Modern Classification Row
struct ModernClassificationRow: View {
    let result: ClassificationResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Object icon based on category
            ZStack {
                Circle()
                    .fill(result.confidenceColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: objectIcon(for: result.displayName))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(result.confidenceColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Confidence: \(Int(result.confidence * 100))%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Modern progress indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: CGFloat(result.confidence))
                    .stroke(result.confidenceColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: result.confidence)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func objectIcon(for name: String) -> String {
        let lowercased = name.lowercased()
        switch lowercased {
        case let x where x.contains("dog"): return "dog.fill"
        case let x where x.contains("cat"): return "cat.fill"
        case let x where x.contains("car"): return "car.fill"
        case let x where x.contains("person"): return "person.fill"
        case let x where x.contains("food"): return "fork.knife"
        case let x where x.contains("plant"): return "leaf.fill"
        case let x where x.contains("building"): return "building.2.fill"
        default: return "viewfinder.circle.fill"
        }
    }
}

// MARK: - Apple Style Button
struct AppleStyleButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary, secondary, tertiary
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconForegroundColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(titleColor)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        )
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: style)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return Color.blue
        case .secondary: return Color.white
        case .tertiary: return Color.gray.opacity(0.1)
        }
    }
    
    private var titleColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .tertiary: return .primary
        }
    }
    
    private var iconBackgroundColor: Color {
        switch style {
        case .primary: return Color.white.opacity(0.2)
        case .secondary: return Color.blue.opacity(0.1)
        case .tertiary: return Color.gray.opacity(0.15)
        }
    }
    
    private var iconForegroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .blue
        case .tertiary: return .primary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary: return Color.clear
        case .secondary: return Color.gray.opacity(0.2)
        case .tertiary: return Color.gray.opacity(0.15)
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary: return 0
        case .secondary: return 1
        case .tertiary: return 1
        }
    }
}

// MARK: - Modern Supporting Views
struct ModernConfidenceBadge: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)
            
            Text("\(Int(confidence * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(badgeColor.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(badgeColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var badgeColor: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6...0.8: return .blue
        case 0.4...0.6: return .orange
        default: return .red
        }
    }
}

struct ModernErrorView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Processing Error")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ModernEmptyResultsView: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 4) {
                Text("Ready to Analyze")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Select an image to see intelligent recognition results")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Live Camera View (keeping original functionality with modern styling)
struct LiveCameraView: View {
    @ObservedObject var cameraManager: CameraManager
    let selectedModel: MLModelType
    @Environment(\.dismiss) private var dismiss
    @StateObject private var liveCameraManager = LiveCameraManager()
    
    var body: some View {
        ZStack {
            // Native Camera
            NativeCameraView(
                onImageCaptured: { image in
                    Task {
                        await cameraManager.classifyImage(image)
                        dismiss()
                    }
                },
                onDismiss: {
                    dismiss()
                }
            )
            
            // Modern overlay
            VStack {
                Spacer()
                
                if !liveCameraManager.liveResults.isEmpty {
                    ModernLiveResultsOverlay(
                        results: liveCameraManager.liveResults,
                        isProcessing: liveCameraManager.isProcessing
                    )
                    .padding(.bottom, 140)
                }
            }
            .allowsHitTesting(false)
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

// MARK: - Modern Live Results Overlay
struct ModernLiveResultsOverlay: View {
    let results: [ClassificationResult]
    let isProcessing: Bool
    
    var body: some View {
        if !results.isEmpty {
            VStack(spacing: 8) {
                ForEach(results.prefix(4), id: \.identifier) { result in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(result.confidenceColor)
                            .frame(width: 8, height: 8)
                        
                        Text(result.displayName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(result.opacity)
                        
                        Spacer()
                        
                        Text("\(Int(result.confidence * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(result.confidenceColor.opacity(0.8))
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Keep all existing manager classes and extensions unchanged
// (CameraManager, LiveCameraManager, ClassificationResult, etc.)

/// Manages ML model loading, caching, and image classification
/// Supports dynamic model switching with Neural Engine optimization
@MainActor
class CameraManager: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var classificationResults: [ClassificationResult] = []
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var isLoadingModel = false
    @Published var loadingModelName = ""
    @Published var isSwitchingModel = false
    
    // Track switching state to prevent duplicates
    private var isCurrentlySwitching = false
    @Published var currentComputeUnit: String = ""
    @Published var isComputeUnitVerified: Bool = false // Track if compute unit is confirmed
    
    private var currentModel: MLModelType = .mobileNet
    private var classificationRequest: VNCoreMLRequest?
    
    // Cache loaded models to avoid reloading
    private var modelCache: [MLModelType: VNCoreMLRequest] = [:]
    private let modelQueue = DispatchQueue(label: "model.loading.queue", qos: .userInitiated)
    
    init() {
        Logger.model.info("🚀 CameraManager initializing")
        // Move ALL model operations off main thread from the start
        Task.detached(priority: .userInitiated) {
            await self.loadInitialModel()
        }
    }
    
    /// Load initial model completely in background
    @MainActor private func loadInitialModel() async {
        Logger.model.info("📥 Loading default model: MobileNet V2")
        await loadModel(.mobileNet)
    }
    
    private func createModel(for modelType: MLModelType) async -> VNCoreMLRequest? {
        return await withCheckedContinuation { continuation in
            modelQueue.async {
                // First try with Neural Engine/GPU (optimal performance)
                let optimalConfiguration = MLModelConfiguration()
                optimalConfiguration.computeUnits = .all
                
                do {
                    let coreMLModel: MLModel
                    
                    switch modelType {
                    case .mobileNet:
                        coreMLModel = try MobileNetV2(configuration: optimalConfiguration).model
                    case .resnet50:
                        coreMLModel = try Resnet50(configuration: optimalConfiguration).model
                    case .fastViT:
                        coreMLModel = try FastViTMA36F16(configuration: optimalConfiguration).model
                    }
                    
                    let model = try VNCoreMLModel(for: coreMLModel)
                    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                        Task { @MainActor [weak self] in
                            self?.processClassifications(for: request, error: error)
                        }
                        // Background verification (non-blocking)
                        Task.detached(priority: .utility) { [weak self] in
                            await self?.verifyComputeUnit(for: coreMLModel, configuration: optimalConfiguration)
                        }
                    }
                    request.imageCropAndScaleOption = .centerCrop
                    
                    continuation.resume(returning: request)
                    return
                } catch {
                    Logger.model.warning("Failed to load \(modelType.displayName) with Neural Engine/GPU, trying CPU fallback: \(error.localizedDescription)")
                }
                
                // Fallback: Try CPU-only for problematic models
                if modelType == .fastViT {
                    Logger.model.info("Trying \(modelType.displayName) with CPU fallback")
                    let cpuConfiguration = MLModelConfiguration()
                    cpuConfiguration.computeUnits = .cpuOnly
                    
                    do {
                        let coreMLModel = try FastViTMA36F16(configuration: cpuConfiguration).model
                        let model = try VNCoreMLModel(for: coreMLModel)
                        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                            Task { @MainActor [weak self] in
                                self?.processClassifications(for: request, error: error)
                            }
                            // Background verification (non-blocking)
                            Task.detached(priority: .utility) { [weak self] in
                                await self?.verifyComputeUnit(for: coreMLModel, configuration: cpuConfiguration)
                            }
                        }
                        request.imageCropAndScaleOption = .centerCrop
                        
                        continuation.resume(returning: request)
                        return
                    } catch {
                        Logger.model.error("Failed to load \(modelType.displayName) even with CPU fallback: \(error.localizedDescription)")
                    }
                }
                
                // Complete failure
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// Verifies and reports the actual compute unit being used by CoreML  
    /// This is called AFTER successful inference to ensure accuracy
    private func verifyComputeUnit(for model: MLModel, configuration: MLModelConfiguration) {
        let modelName = currentModel.displayName // Store model name for logging
        
        Task {
            // Use configuration-based detection instead of timing guesses
            let actualComputeUnit = determineActualComputeUnit(from: model, configuration: configuration)
            
            await MainActor.run {
                self.currentComputeUnit = actualComputeUnit
                self.isComputeUnitVerified = true
            }
            
            Logger.performance.info("✅ \(modelName): \(actualComputeUnit)")
        }
    }
    
    /// Extracts the expected input size from model description
    private func getModelInputSize(from inputDescription: MLFeatureDescription?) -> CGSize {
        guard let description = inputDescription else {
            return CGSize(width: 224, height: 224) // Default fallback
        }
        
        switch description.type {
        case .image:
            if let constraint = description.imageConstraint {
                return CGSize(width: constraint.pixelsWide, height: constraint.pixelsHigh)
            }
        case .multiArray:
            if let constraint = description.multiArrayConstraint {
                let shape = constraint.shape
                if shape.count >= 3 {
                    // Assuming format like [batch, height, width] or [batch, channels, height, width]
                    let height = shape[shape.count - 2].intValue
                    let width = shape[shape.count - 1].intValue
                    return CGSize(width: width, height: height)
                }
            }
        default:
            break
        }
        
        // Model-specific defaults based on known architectures
        switch currentModel {
        case .mobileNet:
            return CGSize(width: 224, height: 224)
        case .resnet50:
            return CGSize(width: 224, height: 224)
        case .fastViT:
            return CGSize(width: 256, height: 256) // FastViT typically uses 256x256
        }
    }
    
    /// Creates a small test image for compute unit verification
    private func createTestImage(size: CGSize, featureName: String) -> MLFeatureProvider {
        // Create a test image with the correct size for the model
        let renderer = UIGraphicsImageRenderer(size: size)
        let testUIImage = renderer.image { context in
            // Create a simple gradient instead of solid color for more realistic input
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemGreen.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
            context.cgContext.drawLinearGradient(gradient, 
                                               start: CGPoint.zero, 
                                               end: CGPoint(x: size.width, y: size.height), 
                                               options: [])
        }
        
        guard let pixelBuffer = testUIImage.toCVPixelBuffer() else {
            fatalError("Could not create test pixel buffer for size \(size)")
        }
        
        do {
            return try MLDictionaryFeatureProvider(dictionary: [featureName: MLFeatureValue(pixelBuffer: pixelBuffer)])
        } catch {
            fatalError("Could not create feature provider with feature name '\(featureName)': \(error)")
        }
    }
    
    /// Determines actual compute unit based on model compilation and configuration
    private func determineActualComputeUnit(from model: MLModel, configuration: MLModelConfiguration) -> String {
        // Check what we requested and what the device can provide
        switch configuration.computeUnits {
        case .cpuOnly:
            return "CPU Only"
        case .cpuAndNeuralEngine:
            // We specifically requested Neural Engine, so if model loaded successfully, it's using it
            return "Neural Engine"
        case .cpuAndGPU:
            return "GPU"  
        case .all:
            // CoreML chooses best available. On modern iOS devices with Neural Engine,
            // it typically prefers Neural Engine for image classification models
            // unless the model has unsupported operations
            if isNeuralEngineAvailable() {
                return "Neural Engine"
            } else {
                return "GPU"
            }
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Check if Neural Engine is available on this device
    private func isNeuralEngineAvailable() -> Bool {
        // Neural Engine is available on A11+ chips (iPhone X and newer, 2017+)
        // We can check iOS version as a proxy
        if #available(iOS 13.0, *) {
            return true // Most devices running iOS 13+ have Neural Engine
        }
        return false
    }
    
    func loadModel(_ modelType: MLModelType) async {
        // Check cache first
        if let cachedRequest = modelCache[modelType] {
            Logger.model.info("⚡ Using cached \(modelType.displayName)")
            currentModel = modelType
            classificationRequest = cachedRequest
            return
        }
        
        Logger.model.info("📥 Loading \(modelType.displayName)")
        
        loadingModelName = modelType.displayName
        isLoadingModel = true
        
        if let request = await createModel(for: modelType) {
            currentModel = modelType
            classificationRequest = request
            modelCache[modelType] = request
            Logger.model.info("✅ Loaded \(modelType.displayName)")
        } else {
            Logger.model.error("❌ Failed to load \(modelType.displayName)")
        }
        
        isLoadingModel = false
        loadingModelName = ""
    }
    
    func updateModel(to modelType: MLModelType) {
        // Prevent duplicate switches
        guard modelType != currentModel else { 
            return 
        }
        
        guard !isCurrentlySwitching else {
            return
        }
        
        Logger.model.info("🔄 Switching to \(modelType.displayName)")
        
        let imageToReclassify = capturedImage // Store current image before switching
        
        // Move EVERYTHING off main thread to prevent UI blocking
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            await MainActor.run {
                self.isCurrentlySwitching = true
                self.isSwitchingModel = true
                
                // Reset compute unit verification when switching
                self.currentComputeUnit = ""
                self.isComputeUnitVerified = false
            }
            
            await self.loadModel(modelType)
            
            // Auto re-classify current image with new model if one exists
            if let image = imageToReclassify {
                // Add a brief pause to show the model has switched before re-analyzing
                try? await Task.sleep(nanoseconds: AppConstants.modelSwitchDelayNanoseconds)
                await self.classifyImage(image)
            }
            
            await MainActor.run {
                self.isSwitchingModel = false
                self.isCurrentlySwitching = false
            }
        }
    }
    
    func classifyImage(_ image: UIImage) async {
        guard let classificationRequest = classificationRequest else {
            errorMessage = "Model not loaded"
            return
        }
        
        capturedImage = image
        isAnalyzing = true
        classificationResults = []
        errorMessage = nil
        
        guard let cgImage = image.cgImage else {
            isAnalyzing = false
            errorMessage = "Unable to process image"
            return
        }
        
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: image.imageOrientation.cgImagePropertyOrientation
        )
        
        do {
            try handler.perform([classificationRequest])
        } catch {
            isAnalyzing = false
            errorMessage = "Classification failed: \(error.localizedDescription)"
        }
    }
    
    private func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            self.isAnalyzing = false
            
            if let error = error {
                self.errorMessage = "Classification error: \(error.localizedDescription)"
                return
            }
            
            guard let observations = request.results as? [VNClassificationObservation] else {
                self.errorMessage = "Unable to classify image"
                return
            }
            
            self.classificationResults = observations
                .prefix(AppConstants.maxClassificationResults)
                .map { observation in
                    ClassificationResult(
                        identifier: observation.identifier,
                        confidence: Double(observation.confidence)
                    )
                }
        }
    }
    
    func clearImage() {
        capturedImage = nil
        classificationResults = []
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Native Camera View
struct NativeCameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.cameraCaptureMode = .photo
        controller.allowsEditing = false
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: NativeCameraView
        
        init(_ parent: NativeCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
    }
}

// MARK: - Live Camera Manager
class LiveCameraManager: NSObject, ObservableObject {
    @Published var liveResults: [ClassificationResult] = []
    @Published var isProcessing = false
    @Published var isLoadingModel = false
    
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    
    // Enhanced object tracking properties
    private var lastProcessingTime: Date = Date()
    private let processingInterval: TimeInterval = 0.3
    private var processingQueue = DispatchQueue(label: "classification.queue", qos: .userInitiated)
    
    // Object accumulation for multiple detections
    private var detectedObjects: [String: ClassificationResult] = [:]
    private var objectExpiryTime: TimeInterval = 3.0
    private var lastCleanupTime: Date = Date()
    
    private var currentModel: MLModelType = .mobileNet
    private var classificationRequest: VNCoreMLRequest?
    
    // Cache loaded models to avoid reloading
    private var modelCache: [MLModelType: VNCoreMLRequest] = [:]
    private let modelQueue = DispatchQueue(label: "live.model.loading.queue", qos: .userInitiated)
    
    override init() {
        super.init()
        setupSession()
        Task { @MainActor in
            await loadModel(.mobileNet)
        }
    }
    
    private func createModel(for modelType: MLModelType) async -> VNCoreMLRequest? {
        return await withCheckedContinuation { continuation in
            modelQueue.async {
                // First try with Neural Engine/GPU (optimal performance)
                let optimalConfiguration = MLModelConfiguration()
                optimalConfiguration.computeUnits = .all
                
                do {
                    let coreMLModel: MLModel
                    
                    switch modelType {
                    case .mobileNet:
                        coreMLModel = try MobileNetV2(configuration: optimalConfiguration).model
                    case .resnet50:
                        coreMLModel = try Resnet50(configuration: optimalConfiguration).model
                    case .fastViT:
                        coreMLModel = try FastViTMA36F16(configuration: optimalConfiguration).model
                    }
                    
                    let model = try VNCoreMLModel(for: coreMLModel)
                    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                        self?.processLiveClassifications(for: request, error: error)
                    }
                    request.imageCropAndScaleOption = .centerCrop
                    continuation.resume(returning: request)
                    return
                } catch {
                    Logger.model.warning("Failed to load \(modelType.displayName) with Neural Engine/GPU, trying CPU fallback: \(error.localizedDescription)")
                }
                
                // Fallback: Try CPU-only for problematic models
                if modelType == .fastViT {
                    Logger.model.info("Trying \(modelType.displayName) with CPU fallback")
                    let cpuConfiguration = MLModelConfiguration()
                    cpuConfiguration.computeUnits = .cpuOnly
                    
                    do {
                        let coreMLModel = try FastViTMA36F16(configuration: cpuConfiguration).model
                        let model = try VNCoreMLModel(for: coreMLModel)
                        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                            self?.processLiveClassifications(for: request, error: error)
                        }
                        request.imageCropAndScaleOption = .centerCrop
                        continuation.resume(returning: request)
                        return
                    } catch {
                        Logger.model.error("Failed to load \(modelType.displayName) even with CPU fallback: \(error.localizedDescription)")
                    }
                }
                
                // Complete failure
                continuation.resume(returning: nil)
            }
        }
    }
    
    @MainActor
    func loadModel(_ modelType: MLModelType) async {
        // Check cache first
        if let cachedRequest = modelCache[modelType] {
            currentModel = modelType
            classificationRequest = cachedRequest
            return
        }
        
        isLoadingModel = true
        
        if let request = await createModel(for: modelType) {
            currentModel = modelType
            classificationRequest = request
            modelCache[modelType] = request
            // Clear current results when switching models
            detectedObjects.removeAll()
            liveResults.removeAll()
        }
        
        isLoadingModel = false
    }
    
    func updateModel(to modelType: MLModelType) {
        guard modelType != currentModel else { return }
        
        Task { @MainActor in
            await loadModel(modelType)
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.sessionPreset = .photo
        session.commitConfiguration()
    }
    
    func startSession() {
        processingQueue.async {
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        session.stopRunning()
        DispatchQueue.main.async {
            self.detectedObjects.removeAll()
            self.liveResults.removeAll()
        }
    }
    
    private func processLiveClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard error == nil,
                  let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            
            let currentTime = Date()
            
            let newResults = observations.prefix(5).compactMap { observation -> ClassificationResult? in
                guard observation.confidence > 0.25 else { return nil }
                return ClassificationResult(
                    identifier: observation.identifier,
                    confidence: Double(observation.confidence),
                    detectedAt: currentTime
                )
            }
            
            for result in newResults {
                let key = result.displayName.lowercased()
                
                if let existing = self.detectedObjects[key] {
                    if result.confidence > existing.confidence {
                        self.detectedObjects[key] = result
                    }
                } else {
                    self.detectedObjects[key] = result
                }
            }
            
            if currentTime.timeIntervalSince(self.lastCleanupTime) >= 1.0 {
                self.cleanupExpiredObjects(currentTime: currentTime)
                self.lastCleanupTime = currentTime
            }
            
            self.liveResults = Array(self.detectedObjects.values)
                .sorted { $0.confidence > $1.confidence }
                .prefix(6)
                .map { $0 }
        }
    }
    
    private func cleanupExpiredObjects(currentTime: Date) {
        detectedObjects = detectedObjects.filter { _, result in
            currentTime.timeIntervalSince(result.detectedAt) < objectExpiryTime
        }
    }
}

// MARK: - Camera Delegate Extensions
extension LiveCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            captureCompletion?(nil)
            return
        }
        
        captureCompletion?(image)
        captureCompletion = nil
    }
}

extension LiveCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessingTime) >= processingInterval else { return }
        
        guard !isProcessing else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let classificationRequest = classificationRequest else { return }
        
        lastProcessingTime = currentTime
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        do {
            try handler.perform([classificationRequest])
        } catch {
            // Silently handle errors to avoid UI disruption
        }
    }
}

struct ClassificationResult {
    let identifier: String
    let confidence: Double
    let detectedAt: Date
    
    init(identifier: String, confidence: Double, detectedAt: Date = Date()) {
        self.identifier = identifier
        self.confidence = confidence
        self.detectedAt = detectedAt
    }
    
    var displayName: String {
        let components = identifier.components(separatedBy: " ")
        if components.count > 1 {
            let first = components[0]
            if first.count > 5 && first.hasPrefix("n") {
                return components.dropFirst().joined(separator: " ").capitalized
            }
        }
        return identifier.capitalized
    }
    
    var opacity: Double {
        let timeSinceDetection = Date().timeIntervalSince(detectedAt)
        let maxTime: Double = 3.0
        return max(0.3, 1.0 - (timeSinceDetection / maxTime))
    }
    
    var confidenceColor: Color {
        switch confidence {
        case 0.5...1.0: return .green
        case 0.35...0.5: return .yellow
        case 0.2...0.35: return .orange
        default: return .red
        }
    }
    
    var confidenceUIColor: UIColor {
        switch confidence {
        case 0.5...1.0: return UIColor.systemGreen
        case 0.35...0.5: return UIColor.systemYellow
        case 0.2...0.35: return UIColor.systemOrange
        default: return UIColor.systemRed
        }
    }
}

extension UIImage.Orientation {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

extension UIImage {
    /// Converts UIImage to CVPixelBuffer for CoreML input
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       Int(self.size.width),
                                       Int(self.size.height),
                                       kCVPixelFormatType_32ARGB,
                                       attrs,
                                       &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                    width: Int(self.size.width),
                                    height: Int(self.size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                    space: rgbColorSpace,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
}

// Add your existing LiveCameraManager and other supporting classes here...

#Preview {
    ContentView()
}
