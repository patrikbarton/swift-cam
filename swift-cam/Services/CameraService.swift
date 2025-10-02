//
//  CameraService.swift
//  swift-cam
//
//  Service for camera session management
//

import AVFoundation
import UIKit

/// Manages AVCaptureSession configuration and camera operations
class CameraService {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    
    /// Setup camera session with photo and video output
    func setupSession(delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        session.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.sessionPreset = .photo
        session.commitConfiguration()
    }
    
    /// Start the camera session
    func startSession(on queue: DispatchQueue) {
        queue.async {
            self.session.startRunning()
        }
    }
    
    /// Stop the camera session
    func stopSession() {
        session.stopRunning()
    }
}

