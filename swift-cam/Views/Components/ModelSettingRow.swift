//
//  ModelSettingRow.swift
//  swift-cam
//
//  Model selection row component for settings
//

import SwiftUI

/// Row component for selecting an ML model
struct ModelSettingRow: View {
    let model: MLModelType
    let isSelected: Bool
    @ObservedObject var viewModel: HomeViewModel
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.appAccent : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    if viewModel.isSwitchingModel && isSelected {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: model.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(isSelected ? .white : .gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(modelDescription(for: model))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appAccent)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(viewModel.isSwitchingModel)
    }
    
    private func modelDescription(for model: MLModelType) -> String {
        switch model {
        case .mobileNet:
            return "Fast and efficient, great for real-time detection"
        case .resnet50:
            return "Higher accuracy, balanced performance"
        case .fastViT:
            return "State-of-the-art Vision Transformer model"
        }
    }
}
