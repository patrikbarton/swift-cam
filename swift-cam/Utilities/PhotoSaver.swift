
//
//  PhotoSaver.swift
//  swift-cam
//
//  Created by Joshua Noeldeke on 10/13/25.
//

import Photos
import OSLog
import CoreLocation

class PhotoSaver: NSObject {
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
