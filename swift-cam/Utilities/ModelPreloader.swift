// ModelPreloader.swift
// Preloads and caches Core ML models during splash screen for optimal first-use performance
// Models are pre-compiled by Xcode to .mlmodelc format and loaded into memory here

import Foundation
import CoreML
import OSLog

/// Data structure for communicating model loading progress
struct ModelLoadProgress {
    let message: String
    let current: Int
    let total: Int
}

/// Actor for thread-safe progress counting during parallel loading
private actor ProgressCounter {
    var value = 0
    func increment() -> Int {
        value += 1
        return value
    }
}

struct ModelPreloader {
    /// Preloads all models in parallel by calling the shared ModelService.
    /// This populates the application-level cache for instant first-use access.
    /// Progress updates are reported via the `progress` closure using a structured object.
    ///
    /// - Parameter progress: Closure called with `ModelLoadProgress` updates.
    static func preloadAll(progress: @escaping (ModelLoadProgress) -> Void) async {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "swift-cam", category: "ModelPreloader")
        logger.info("🚀 Starting full two-stage model preloading...")

        let models: [MLModelType] = [.mobileNet, .resnet50, .fastViT]
        let totalModels = models.count
        let counter = ProgressCounter()

        progress(ModelLoadProgress(message: "Initializing...", current: 0, total: totalModels))

        // --- Stage 1: Pre-load MLModel objects ---
        logger.info("🔥 Stage 1: Pre-loading MLModel objects into ModelService cache...")
        await withTaskGroup(of: Void.self) { group in
            for modelType in models {
                let displayName = modelType.displayName
                group.addTask {
                    let modelNumber = await counter.increment()
                    
                    let message = "Loading \(displayName)..."
                    progress(ModelLoadProgress(message: message, current: modelNumber, total: totalModels))
                    logger.info("📦 [\(modelNumber, privacy: .public)/\(totalModels, privacy: .public)] Submitting \(displayName, privacy: .public) to ModelService for loading.")

                    let modelStart = Date()
                    do {
                        _ = try await ModelService.shared.loadCoreMLModel(for: modelType)
                        let modelDuration = Date().timeIntervalSince(modelStart)
                        logger.info("✅ [\(modelNumber, privacy: .public)/\(totalModels, privacy: .public)] \(displayName, privacy: .public) loaded and cached by ModelService in \(String(format: "%.2f", modelDuration), privacy: .public)s")
                    } catch {
                        logger.error("❌ Failed to preload \(displayName, privacy: .public) via ModelService: \(error.localizedDescription, privacy: .public)")
                        let errorMessage = "Failed: \(displayName)"
                        progress(ModelLoadProgress(message: errorMessage, current: modelNumber, total: totalModels))
                    }
                }
            }
        }
        logger.info("✅ Stage 1 complete. All MLModel objects are cached.")

        // --- Stage 2: Pre-warm VNCoreMLModel objects ---
        logger.info("🔥 Stage 2: Pre-warming VNCoreMLModel objects in VisionService...")
        await VisionService.shared.prewarmAllModels()
        logger.info("✅ Stage 2 complete. All Vision models are pre-warmed.")

        // --- Final Progress Update ---
        progress(ModelLoadProgress(message: "All models ready!", current: totalModels, total: totalModels))
        logger.info("✅ All model preloading and pre-warming complete.")
    }
}
