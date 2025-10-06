//
//  CIImage+Extensions.swift
//  swift-cam
//
//  CIImage utility extensions, particularly for image processing.
//

import CoreImage

extension CIImage {
    
    /// Creates a new version of the image cropped to a center square.
    /// This is the core, shared logic for ensuring what the user sees (WYSIWYG)
    /// matches the `.centerCrop` behavior of the Vision framework.
    /// - Returns: A new `CIImage` cropped to a square.
    func croppedToCenterSquare() -> CIImage {
        let imageExtent = self.extent
        let shorterSide = min(imageExtent.width, imageExtent.height)
        
        // Calculate the origin for the crop rectangle to center it
        let croppingRect = CGRect(
            x: (imageExtent.width - shorterSide) / 2.0,
            y: (imageExtent.height - shorterSide) / 2.0,
            width: shorterSide,
            height: shorterSide
        )
        
        return self.cropped(to: croppingRect)
    }
}
