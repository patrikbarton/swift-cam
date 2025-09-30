import SwiftUI
import PhotosUI
import Combine
import CoreML
import Vision
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var showingLiveCamera = false
    
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
                                    
                                    Text("Intelligent Image Recognition")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Apple-style icon
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
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
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await cameraManager.classifyImage(image)
                }
            }
        }
        .fullScreenCover(isPresented: $showingLiveCamera) {
            LiveCameraView(cameraManager: cameraManager)
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
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 280)
                    .clipped()
                    .cornerRadius(24)
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
        .frame(height: 280)
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
                ForEach(results.prefix(5), id: \.identifier) { result in
                    ModernClassificationRow(result: result)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity.combined(with: .scale(scale: 0.8))
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: results.count)
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

@MainActor
class CameraManager: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var classificationResults: [ClassificationResult] = []
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MobileNetV2(configuration: MLModelConfiguration()).model)
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func classifyImage(_ image: UIImage) async {
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
                .prefix(5)
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
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MobileNetV2(configuration: MLModelConfiguration()).model)
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processLiveClassifications(for: request, error: error)
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    override init() {
        super.init()
        setupSession()
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
        case 0.8...1.0: return .green
        case 0.6...0.8: return .blue
        case 0.4...0.6: return .orange
        case 0.25...0.4: return .yellow
        default: return .red
        }
    }
    
    var confidenceUIColor: UIColor {
        switch confidence {
        case 0.8...1.0: return UIColor.systemGreen
        case 0.6...0.8: return UIColor.systemBlue
        case 0.4...0.6: return UIColor.systemOrange
        case 0.25...0.4: return UIColor.systemYellow
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

// Add your existing LiveCameraManager and other supporting classes here...

#Preview {
    ContentView()
}
