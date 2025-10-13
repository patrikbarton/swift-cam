//
//  FaceBlurring.swift
//  swift-cam
//
//  Face detection and blurring service for privacy protection
//

import Vision
import CoreImage
import UIKit
import OSLog

/// Service for detecting and blurring faces in images and video frames
class FaceBlurringService {
    private let context = CIContext()
    
    /// Detect faces and apply blur to a UIImage
    /// - Parameters:
    ///   - image: The image to process
    ///   - blurRadius: The radius of the blur effect (default: 20.0)
    ///   - blurStyle: The style of blur to apply
    /// - Returns: Image with blurred faces, or original if no faces detected
    func blurFaces(in image: UIImage, blurRadius: Double = 20.0, blurStyle: BlurStyle = .gaussian) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw FaceBlurError.invalidImage
        }
        
        // Create face detection request
        let faceRequest = VNDetectFaceRectanglesRequest()
        
        // Perform face detection
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: image.imageOrientation.cgImagePropertyOrientation
        )
        try handler.perform([faceRequest])
        
        guard let faces = faceRequest.results, !faces.isEmpty else {
            // No faces detected, return original
            Logger.privacy.debug("🔒 No faces detected in image")
            return image
        }
        
        Logger.privacy.info("🔒 Detected \(faces.count) face(s), applying blur")
        
        // Convert to CIImage for filtering
        guard var ciImage = CIImage(image: image) else {
            throw FaceBlurError.invalidImage
        }
        
        // Apply blur to each detected face
        for face in faces {
            let boundingBox = face.boundingBox
            
            // Convert normalized coordinates to image coordinates
            let imageSize = ciImage.extent.size
            let faceRect = VNImageRectForNormalizedRect(
                boundingBox,
                Int(imageSize.width),
                Int(imageSize.height)
            )
            
            // Expand the face rect slightly to ensure full coverage
            let expandedRect = faceRect.insetBy(dx: -faceRect.width * 0.1, dy: -faceRect.height * 0.1)
            
            // Apply the selected blur style
            if let blurredRegion = applyBlur(to: ciImage, region: expandedRect, style: blurStyle, radius: blurRadius) {
                ciImage = blurredRegion
            }
        }
        
        // Convert back to UIImage
        guard let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw FaceBlurError.processingFailed
        }
        
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// Blur faces in a pixel buffer (for real-time video processing)
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer from camera feed
    ///   - blurRadius: The radius of the blur effect
    ///   - blurStyle: The style of blur to apply
    /// - Returns: CIImage with blurred faces, or nil if processing fails
    func blurFaces(in pixelBuffer: CVPixelBuffer, blurRadius: Double = 15.0, blurStyle: BlurStyle = .gaussian) async throws -> CIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let faceRequest = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try handler.perform([faceRequest])
        
        guard let faces = faceRequest.results, !faces.isEmpty else {
            return ciImage // No faces, return original
        }
        
        var processedImage = ciImage
        
        for face in faces {
            let boundingBox = face.boundingBox
            let imageSize = processedImage.extent.size
            let faceRect = VNImageRectForNormalizedRect(
                boundingBox,
                Int(imageSize.width),
                Int(imageSize.height)
            )
            
            // Expand slightly for better coverage
            let expandedRect = faceRect.insetBy(dx: -faceRect.width * 0.1, dy: -faceRect.height * 0.1)
            
            if let blurredRegion = applyBlur(to: processedImage, region: expandedRect, style: blurStyle, radius: blurRadius) {
                processedImage = blurredRegion
            }
        }
        
        return processedImage
    }
    
    /// Apply blur effect to a specific region of an image
    private func applyBlur(to image: CIImage, region: CGRect, style: BlurStyle, radius: Double) -> CIImage? {
        let faceImage = image.cropped(to: region)
        
        switch style {
        case .gaussian:
            guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
            blurFilter.setValue(faceImage, forKey: kCIInputImageKey)
            blurFilter.setValue(radius, forKey: kCIInputRadiusKey)
            
            guard let blurredFace = blurFilter.outputImage?.cropped(to: faceImage.extent) else { return nil }
            return blurredFace.composited(over: image)
            
        case .pixelated:
            guard let pixellateFilter = CIFilter(name: "CIPixellate") else { return nil }
            pixellateFilter.setValue(faceImage, forKey: kCIInputImageKey)
            pixellateFilter.setValue(max(radius, 8.0), forKey: kCIInputScaleKey)
            
            guard let pixellatedFace = pixellateFilter.outputImage?.cropped(to: faceImage.extent) else { return nil }
            return pixellatedFace.composited(over: image)
            
        case .blackBox:
            let blackRect = CIImage(color: CIColor.black).cropped(to: region)
            return blackRect.composited(over: image)
        }
    }
}

/// Blur style options for face privacy
enum BlurStyle: String, CaseIterable, Hashable {
    case gaussian = "Gaussian Blur"
    case pixelated = "Pixelated"
    case blackBox = "Black Box"
    
    var description: String {
        switch self {
        case .gaussian:
            return "Smooth blur effect"
        case .pixelated:
            return "Pixelation effect (retro)"
        case .blackBox:
            return "Solid black rectangle (maximum privacy)"
        }
    }
}

/// Errors that can occur during face blurring
enum FaceBlurError: Error, LocalizedError {
    case invalidImage
    case processingFailed
    case noFacesDetected
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .processingFailed:
            return "Failed to process image"
        case .noFacesDetected:
            return "No faces detected"
        }
    }
}

// MARK: - Logger Extension
extension Logger {
    static let privacy = Logger(subsystem: Bundle.main.bundleIdentifier ?? "swift-cam", category: "Privacy")
}

