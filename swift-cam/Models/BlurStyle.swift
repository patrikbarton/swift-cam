import Foundation

// MARK: - Blur Style Options

/// Blur style options for face privacy protection
enum BlurStyle: String, CaseIterable, Hashable {
    case gaussian = "Gaussian Blur"
    case pixelated = "Pixelated"
    case blackBox = "Black Box"
    
    /// User-friendly description of the blur style
    var description: String {
        switch self {
        case .gaussian:
            return "Smooth blur effect"
        case .pixelated:
            return "Pixelation effect (retro)"
        case .blackBox:
            return "Solid black rectangle (maximum privacy)"
        }
    }
}
