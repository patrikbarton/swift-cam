//
//  CaptureButton.swift
//  swift-cam
//
//  Standard iOS-style camera capture button component
//

import SwiftUI

/// Standard camera shutter button with classic iOS design
///
/// Displays the familiar circular capture button with:
/// - White outer ring (4pt stroke)
/// - White inner circle (60pt diameter)
/// - Total size: 70pt diameter
///
/// **Design:**
/// Matches the standard iOS Camera app aesthetic for
/// immediate user recognition and intuitive interaction.
///
/// **Usage:**
/// ```swift
/// CaptureButton {
///     // Capture photo
///     capturePhoto()
/// }
/// ```
struct CaptureButton: View {
    
    /// Action to perform when button is tapped
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 4)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
            }
        }
    }
}

#Preview {
    CaptureButton(action: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

