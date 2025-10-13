//
//  CameraPreviewView.swift
//  swift-cam
//
//  UIKit-wrapped camera preview layer for AVCaptureSession
//

import SwiftUI
import AVFoundation

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer
///
/// Bridges AVFoundation's camera preview into SwiftUI views using
/// `UIViewRepresentable` protocol.
///
/// **Configuration:**
/// - Uses `.resizeAspectFill` to fill frame and crop excess
/// - Black background for letterboxing
/// - Automatic orientation handling
///
/// **Usage:**
/// ```swift
/// CameraPreviewView(session: captureSession)
///     .frame(width: 390, height: 390) // Square camera
/// ```
struct CameraPreviewView: UIViewRepresentable {
    
    // MARK: - Inner View
    
    /// UIView subclass that uses AVCaptureVideoPreviewLayer as its backing layer
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }

    // MARK: - Properties
    
    /// The AVCaptureSession to display
    let session: AVCaptureSession

    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        // KEY: .resizeAspectFill ensures the camera fills the square and crops excess
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // No update needed
    }
}

