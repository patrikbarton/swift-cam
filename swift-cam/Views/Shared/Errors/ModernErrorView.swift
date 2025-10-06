//
//  ModernErrorView.swift
//  swift-cam
//
//  Error display component
//

import SwiftUI

struct ModernErrorView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Processing Error")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ModernErrorView(message: "This is a sample error message to demonstrate how the view will look.")
        .padding()
        .background(Color(.systemGroupedBackground))
}

