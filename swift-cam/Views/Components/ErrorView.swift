//
//  ErrorView.swift
//  swift-cam
//
//  Error display component
//

import SwiftUI

struct ErrorView: View {
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
                    .font(.system(.body, design: .default, weight: .semibold)) // SF Pro
                    .foregroundColor(.black) // Dark text on white background
                
                Text(message)
                    .font(.system(.subheadline, design: .default, weight: .medium)) // SF Pro
                    .foregroundColor(.gray) // Gray for secondary text
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
    ErrorView(message: "This is a sample error message to demonstrate how the view will look.")
        .padding()
        .background(Color(.systemGroupedBackground))
}

