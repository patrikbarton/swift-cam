//
//  MLModelType.swift
//  swift-cam
//
//  Defines available ML models for image classification
//

import Foundation

/// Represents the available machine learning models for image classification
enum MLModelType: String, CaseIterable, Identifiable {
    case mobileNet = "MobileNetV2"
    case resnet50 = "Resnet50"
    case fastViT = "FastViTMA36F16"
    
    var id: String { rawValue }
    
    /// Human-readable display name for the model
    var displayName: String {
        switch self {
        case .mobileNet: return "MobileNet V2"
        case .resnet50: return "ResNet-50"
        case .fastViT: return "FastViT"
        }
    }
    
    var shortName: String {
        switch self {
        case .mobileNet: return "MobileNet"
        case .resnet50: return "ResNet"
        case .fastViT: return "FastViT"
        }
    }
    
    /// Brief description of the model's characteristics
    var description: String {
        switch self {
        case .mobileNet: return "Efficient & Fast"
        case .resnet50: return "High Accuracy"
        case .fastViT: return "Vision Transformer"
        }
    }
    
    /// SF Symbol icon representing the model
    var icon: String {
        switch self {
        case .mobileNet: return "bolt.fill"
        case .resnet50: return "target"
        case .fastViT: return "eye.fill"
        }
    }
}

