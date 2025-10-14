//
//  CameraPreviewView.swift
//  swift-cam
//
//  A SwiftUI View that displays the live video feed from an AVCaptureSession.
//

import SwiftUI
import AVFoundation

/// A SwiftUI view that wraps a UIKit `UIView` to display the live video feed from an `AVCaptureSession`.
///
/// This component is essential for showing the camera's output within a SwiftUI view hierarchy.
/// It uses the `UIViewRepresentable` protocol to bridge `AVCaptureVideoPreviewLayer`.
///
/// **Implementation Details:**
/// - Contains a nested `UIView` subclass, `VideoPreviewView`, whose backing layer is set to `AVCaptureVideoPreviewLayer`.
/// - The `makeUIView` method connects the provided `AVCaptureSession` to this layer.
/// - `videoGravity` is set to `.resizeAspectFill` to ensure the camera feed fills the available space, cropping as necessary.
///
/// **Usage:**
/// ```swift
/// struct MyView: View {
///     let session: AVCaptureSession
///
///     var body: some View {
///         CameraPreviewView(session: session)
///             .ignoresSafeArea()
///     }
/// }
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

#Preview {
    // Note: The camera feed is not available in SwiftUI previews.
    // This will just render the black background of the view.
    CameraPreviewView(session: AVCaptureSession())
        .frame(width: 300, height: 300)
        .border(Color.red, width: 2)
}

