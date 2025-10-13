
//
//  PhotoSaver.swift
//  swift-cam
//
//  Created by Joshua Noel on 10/13/25.
//

import Photos
import OSLog

class PhotoSaver: NSObject {
    func saveImageData(_ data: Data) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard let self = self else { return }
            
            guard status == .authorized else {
                Logger.bestShot.error("Photo library access denied.")
                return
            }
            
            self.performSave(data)
        }
    }

    private func performSave(_ data: Data) {
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: data, options: nil)
        }) { (success, error) in
            if let error = error {
                Logger.bestShot.error("Failed to save photo: \(error.localizedDescription)")
            } else {
                Logger.bestShot.info("Photo saved successfully with metadata.")
            }
        }
    }
}
