import Foundation
import CoreGraphics

/// Gets the input size required for a model
/// - Parameter modelType: The model to query
/// - Returns: Expected input size (width, height)
func getInputSize(for modelType: MLModelType) -> CGSize {
    switch modelType {
    case .mobileNet, .resnet50:
        return CGSize(width: 224, height: 224)
    case .fastViT:
        return CGSize(width: 256, height: 256)
    }
}
