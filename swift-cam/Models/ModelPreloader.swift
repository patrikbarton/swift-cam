// ModelPreloader.swift
// Preloads and caches Core ML models during splash screen for optimal first-use performance
// Models are pre-compiled by Xcode to .mlmodelc format and loaded into memory here

import Foundation
import CoreML
import OSLog

struct ModelPreloader {
    /// Preloads all models found in the app bundle by loading the pre-compiled models into memory.
    /// This ensures models are ready for instant use, eliminating first-use loading delays.
    /// Progress updates are reported via the `progress` closure to display real-time loading status.
    /// 
    /// - Parameter progress: Closure called with progress updates (e.g., "Loading MobileNet V2...")
    static func preloadAll(progress: @escaping (String) -> Void) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "swift-cam", category: "ModelPreloader")
        
        logger.info("🚀 Starting model preloading - loading pre-compiled ML models")

        let models: [(display: String, resource: String)] = [
            ("MobileNet V2", "MobileNetV2"),
            ("ResNet-50", "Resnet50"),
            ("FastViT", "FastViTMA36F16")
        ]

        for (index, (display, resource)) in models.enumerated() {
            let modelNumber = index + 1
            let totalModels = models.count
            
            progress("Loading \(display)... (\(modelNumber)/\(totalModels))")
            logger.info("📦 [\(modelNumber)/\(totalModels)] Loading \(display)")
            
            let modelStart = Date()

            do {
                // Get bundle on main thread
                let bundle = Bundle.main
                
                // Xcode automatically compiles .mlmodel and .mlpackage files to .mlmodelc during build
                // Look for the pre-compiled .mlmodelc bundle in the app bundle
                guard let modelURL = bundle.url(forResource: resource, withExtension: "mlmodelc") else {
                    throw NSError(domain: "ModelPreloader", code: 1, 
                                userInfo: [NSLocalizedDescriptionKey: "Compiled model not found: \(resource).mlmodelc"])
                }
                
                // Load the pre-compiled model into memory on background thread
                try await Task.detached {
                    _ = try MLModel(contentsOf: modelURL)
                }.value
                
                let modelDuration = Date().timeIntervalSince(modelStart)
                logger.info("✅ [\(modelNumber)/\(totalModels)] \(display) loaded successfully in \(String(format: "%.2f", modelDuration))s")
                
                progress("✓ \(display)")

            } catch {
                logger.error("❌ Failed to preload \(display): \(error.localizedDescription)")
                progress("Failed: \(display)")
                // Continue with other models even if one fails
            }
        }

        progress("Ready!")
        logger.info("✅ All model preloading complete - app ready for use")
    }
}
