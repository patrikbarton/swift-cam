//
//  ErrorView.swift
//  swift-cam
//
//  Error message display component
//

import SwiftUI

/// Error message display with icon and description
///
/// Shows user-friendly error messages with:
/// - Red warning triangle icon
/// - "Processing Error" header
/// - Detailed error message
/// - Red-tinted background
///
/// **Design:**
/// Soft red background with border, clear hierarchy,
/// SF Pro system font for native iOS look.
///
/// **Usage:**
/// ```swift
/// ErrorView(message: "Unable to load image")
/// ```
struct ErrorView: View {
    
    /// Error message to display
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

