//
//  CameraSessionManager.swift
//  swift-cam
//
//  Service for managing AVCaptureSession and camera device switching
//

import AVFoundation
import OSLog

/// Manages camera session lifecycle and device switching
///
/// Handles all low-level camera operations:
/// - Session setup and configuration
/// - Device discovery (ultra-wide, wide, telephoto)
/// - Device switching (front/back, multi-camera)
/// - Session lifecycle (start/stop)
///
/// **Usage:**
/// ```swift
/// let manager = CameraSessionManager()
/// manager.setupSession(photoOutput: photoOutput, videoOutput: videoOutput)
/// manager.startSession()
/// manager.switchToDevice(wideCamera)
/// ```
class CameraSessionManager {
    
    // MARK: - Properties
    
    let session = AVCaptureSession()
    private(set) var availableBackCameras: [AVCaptureDevice] = []
    private(set) var activeCamera: AVCaptureDevice?
    
    private let processingQueue = DispatchQueue(label: "camera.processing.queue", qos: .userInitiated)
    
    // MARK: - Callbacks
    
    /// Called when available cameras are discovered
    var onCamerasDiscovered: (([AVCaptureDevice]) -> Void)?
    
    /// Called when active camera changes
    var onActiveCameraChanged: ((AVCaptureDevice) -> Void)?
    
    // MARK: - Setup
    
    /// Setup camera session with outputs
    ///
    /// - Parameters:
    ///   - photoOutput: Photo capture output
    ///   - videoOutput: Video data output for frame processing
    func setupSession(photoOutput: AVCapturePhotoOutput, videoOutput: AVCaptureVideoDataOutput) {
        session.beginConfiguration()
        
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
    }
    
    /// Discover available cameras and set initial camera
    func discoverAndSetInitialCamera() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        )
        
        availableBackCameras = discoverySession.devices
        Logger.cameraSetup.log("📸 Discovered back cameras: \(self.availableBackCameras.map { $0.localizedName })")
        
        onCamerasDiscovered?(availableBackCameras)
        
        // Default to wide camera
        if let wideCamera = availableBackCameras.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
            switchToDevice(wideCamera)
        } else if let firstAvailable = availableBackCameras.first {
            switchToDevice(firstAvailable)
        }
    }
    
    // MARK: - Device Switching
    
    /// Switch to a specific camera device
    ///
    /// - Parameter device: The camera device to switch to
    func switchToDevice(_ device: AVCaptureDevice) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }
            
            // Remove current input
            if let currentInput = self.session.inputs.first {
                self.session.removeInput(currentInput)
            }
            
            // Add new input
            guard let input = try? AVCaptureDeviceInput(device: device) else {
                Logger.cameraSetup.error("Could not create input for device \(device.localizedName).")
                return
            }
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.activeCamera = device
                Logger.cameraSetup.log("✅ Switched to camera: \(device.localizedName)")
                
                DispatchQueue.main.async {
                    self.onActiveCameraChanged?(device)
                }
            } else {
                Logger.cameraSetup.error("Cannot add input for device \(device.localizedName).")
            }
        }
    }
    
    /// Toggle between front and back camera
    func toggleFrontBack() {
        let newPosition: AVCaptureDevice.Position = (activeCamera?.position == .back) ? .front : .back
        
        if newPosition == .front {
            // Switch to front camera
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .front
            )
            
            if let device = discoverySession.devices.first {
                switchToDevice(device)
            }
            
            // Clear back cameras list when on front camera
            availableBackCameras = []
            onCamerasDiscovered?([])
        } else {
            // Switch back to rear cameras
            discoverAndSetInitialCamera()
        }
    }
    
    // MARK: - Session Control
    
    /// Start the camera session
    func startSession() {
        processingQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    /// Stop the camera session
    func stopSession() {
        session.stopRunning()
    }
}
