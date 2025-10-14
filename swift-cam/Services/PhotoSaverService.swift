//
//  PhotoSaverService.swift
//  swift-cam
//
//  Service for saving photos to the device's Photo Library
//

import Photos
import OSLog
import CoreLocation

/// Service for saving photos to the Photo Library with metadata
///
/// Handles photo library authorization and saves images with optional
/// location metadata. All operations are asynchronous and thread-safe.
///
/// **Photo Library Authorization:**
/// - Requests `.addOnly` permission (write-only, no read access needed)
/// - Gracefully handles denied access
///
/// **Metadata Support:**
/// - Location (CLLocation) automatically embedded in EXIF
/// - Creation date preserved
///
/// **Usage:**
/// ```swift
/// let service = PhotoSaverService()
/// service.saveImageData(jpegData, location: currentLocation)
/// ```
class PhotoSaverService: NSObject {
    
    // MARK: - Public Methods
    
    /// Save image data to Photo Library with optional location
    ///
    /// Requests authorization if needed, then saves the photo.
    /// Logs success/failure but does not throw errors.
    ///
    /// - Parameters:
    ///   - data: JPEG image data to save
    ///   - location: Optional location to embed in photo metadata
    func saveImageData(_ data: Data, location: CLLocation?) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard let self = self else { return }
            
            guard status == .authorized else {
                Logger.bestShot.error("Photo library access denied.")
                return
            }
            
            self.performSave(data, location: location)
        }
    }

    // MARK: - Private Methods
    
    /// Perform the actual photo save operation
    ///
    /// - Parameters:
    ///   - data: Image data to save
    ///   - location: Optional location metadata
    private func performSave(_ data: Data, location: CLLocation?) {
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: data, options: nil)
            creationRequest.location = location
        }) { (success, error) in
            if let error = error {
                Logger.bestShot.error("Failed to save photo: \(error.localizedDescription)")
            } else {
                Logger.bestShot.info("Photo saved successfully with metadata.")
            }
        }
    }
}
