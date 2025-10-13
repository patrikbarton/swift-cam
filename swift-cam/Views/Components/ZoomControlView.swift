//
//  ZoomControlView.swift
//  swift-cam
//
//  Multi-camera zoom selector (0.5x, 1x, 3x)
//

import SwiftUI
import AVFoundation

/// Multi-camera zoom control for switching between device cameras
///
/// Provides iPhone-style zoom buttons for available camera devices:
/// - **0.5x** - Ultra-wide camera (13mm equivalent)
/// - **1x** - Wide-angle camera (26mm equivalent)
/// - **3x** - Telephoto camera (77mm equivalent)
///
/// **Behavior:**
/// - Only shows buttons for available cameras on device
/// - Highlights currently active camera
/// - Switches camera device on tap (not digital zoom)
/// - Automatic sorting by focal length
///
/// **Design:**
/// Pill-shaped segmented control with glass morphism effect,
/// matching iOS Camera app aesthetic.
///
/// **Usage:**
/// ```swift
/// ZoomControlView(manager: liveCameraViewModel)
/// ```
struct ZoomControlView: View {
    @ObservedObject var manager: LiveCameraViewModel

    // MARK: - Private Helpers
    
    /// Sort order for camera devices (ultra-wide → wide → telephoto)
    private func deviceOrder(_ deviceType: AVCaptureDevice.DeviceType) -> Int {
        switch deviceType {
        case .builtInUltraWideCamera: return 0
        case .builtInWideAngleCamera: return 1
        case .builtInTelephotoCamera: return 2
        default: return 99
        }
    }

    /// Display label for camera device (0.5x, 1x, 3x)
    private func label(for device: AVCaptureDevice) -> String {
        switch device.deviceType {
        case .builtInUltraWideCamera: return "0.5x"
        case .builtInWideAngleCamera: return "1x"
        case .builtInTelephotoCamera:
            // Heuristic for telephoto zoom level
            if device.localizedName.contains("Telephoto") {
                return "3x"
            }
            return "2x"
        default: return "?"
        }
    }

    var body: some View {
        // Only show controls if there are multiple physical back cameras
        if manager.availableBackCameras.count > 1 {
            HStack(spacing: 8) {
                ForEach(manager.availableBackCameras.sorted(by: { deviceOrder($0.deviceType) < deviceOrder($1.deviceType) }), id: \.uniqueID) { device in
                    Button(action: {
                        manager.switchToDevice(device)
                    }) {
                        Text(label(for: device))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(manager.activeCamera == device ? .appSecondary : .white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(manager.activeCamera == device ? 0.6 : 0.4))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}

#if DEBUG
import AVFoundation

class MockLiveCameraViewModel: LiveCameraViewModel {
    override init() {
        super.init()
#if !targetEnvironment(simulator)
        let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
        let ultraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        let telephoto = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
        
        self.availableBackCameras = [wide, ultraWide, telephoto].compactMap { $0 }
        self.activeCamera = wide
#endif
    }
}

#Preview {
    let mockManager = MockLiveCameraViewModel()
    return ZoomControlView(manager: mockManager)
        .padding()
        .background(Color.black)
}
#endif

