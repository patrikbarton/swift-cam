//
//  ZoomControlView.swift
//  swift-cam
//
//  Multi-camera zoom control (0.5x, 1x, 3x)
//

import SwiftUI
import AVFoundation

struct ZoomControlView: View {
    @ObservedObject var manager: LiveCameraViewModel

    private func deviceOrder(_ deviceType: AVCaptureDevice.DeviceType) -> Int {
        switch deviceType {
        case .builtInUltraWideCamera: return 0
        case .builtInWideAngleCamera: return 1
        case .builtInTelephotoCamera: return 2
        default: return 99
        }
    }

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

