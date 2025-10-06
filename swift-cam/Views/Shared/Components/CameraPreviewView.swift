//
//  CameraPreviewView.swift
//  swift-cam
//
//  Camera preview layer wrapper for AVCaptureSession
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }

    let session: AVCaptureSession

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

