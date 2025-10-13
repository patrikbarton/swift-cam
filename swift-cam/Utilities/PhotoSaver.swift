
//
//  PhotoSaver.swift
//  swift-cam
//
//  Created by Joshua Noel on 10/13/25.
//

import UIKit
import OSLog

class PhotoSaver: NSObject {
    func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            Logger.bestShot.error("Failed to save photo: \(error.localizedDescription)")
        } else {
            Logger.bestShot.info("Photo saved successfully.")
        }
    }
}
