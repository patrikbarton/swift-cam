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
                // Enhanced Icon Container with Liquid Glass (Optimized)
                ZStack {
                    // Simplified glow - no blur for better performance
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.appAccent.opacity(0.3), Color.appAccent.opacity(0)],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 33
                                )
                            )
                            .frame(width: 66, height: 66)
                    }

                    // Main circle with combined gradient
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [Color.appAccent, Color.appSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .fill(.thinMaterial.opacity(isSelected ? 0.2 : 0.4))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.2),
                                    lineWidth: 1.5
                                )
                        )
                        .frame(width: 56, height: 56)
                    
                    if viewModel.isSwitchingModel && isSelected {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: model.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.displayName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(modelDescription(for: model))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                        .lineSpacing(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.appAccent)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: isSelected ?
                                        [Color.appAccent.opacity(0.2), Color.appSecondary.opacity(0.1)] :
                                        [Color.white.opacity(0.05), Color.white.opacity(0.01)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                isSelected ? Color.appAccent.opacity(0.5) : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.appAccent.opacity(0.2) : Color.black.opacity(0.08),
                radius: isSelected ? 12 : 8,
                y: isSelected ? 4 : 2
            )
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

#Preview {
    // This wrapper view is necessary to use @StateObject in a preview.
    struct ModelSettingRowPreviewWrapper: View {
        @StateObject private var viewModel = HomeViewModel()
        
        var body: some View {
            VStack(spacing: 12) {
                // Example of a selected row
                ModelSettingRow(
                    model: .mobileNet,
                    isSelected: true,
                    viewModel: viewModel,
                    onSelect: {}
                )
                
                // Example of a non-selected row
                ModelSettingRow(
                    model: .resnet50,
                    isSelected: false,
                    viewModel: viewModel,
                    onSelect: {}
                )
                
                // Example of a row in the "switching" state
                ModelSettingRow(
                    model: .fastViT,
                    isSelected: true,
                    viewModel: { 
                        let vm = HomeViewModel()
                        vm.isSwitchingModel = true // Manually set the state for preview
                        return vm
                    }(),
                    onSelect: {}
                )
            }
            .padding()
            .background(Color.appPrimary.opacity(0.8))
        }
    }
    
    return ModelSettingRowPreviewWrapper()
}
