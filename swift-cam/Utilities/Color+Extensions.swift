//
//  Color+Extensions.swift
//  swift-cam
//
//  Custom color palette extensions
//

import SwiftUI

extension Color {
    // MARK: - Custom App Color Palette
    
    /// Primary color - Mint/Sage Green (#A8D5BA)
    static let appPrimary = Color(red: 0xA8 / 255.0, green: 0xD5 / 255.0, blue: 0xBA / 255.0)
    
    /// Secondary color - Soft Pink (#FFB4C4)
    static let appSecondary = Color(red: 0xFF / 255.0, green: 0xB4 / 255.0, blue: 0xC4 / 255.0)
    
    /// Accent color - Purple (#8B7EC8)
    static let appAccent = Color(red: 0x8B / 255.0, green: 0x7E / 255.0, blue: 0xC8 / 255.0)
    
    /// Light background color - Very Light Green (#F0FFF4)
    static let appLight = Color(red: 0xF0 / 255.0, green: 0xFF / 255.0, blue: 0xF4 / 255.0)
    
    // MARK: - Gradient Helpers
    
    /// Primary gradient colors for backgrounds
    static let appPrimaryGradient = [
        appPrimary.opacity(0.6),
        appPrimary.opacity(0.3)
    ]
    
    /// Secondary gradient colors for backgrounds
    static let appSecondaryGradient = [
        appSecondary.opacity(0.5),
        appSecondary.opacity(0.3)
    ]
    
    /// Accent gradient colors for backgrounds
    static let appAccentGradient = [
        appAccent.opacity(0.6),
        appAccent.opacity(0.3)
    ]
    
    /// Mixed gradient for variety
    static let appMixedGradient1 = [
        appPrimary.opacity(0.5),
        appAccent.opacity(0.4)
    ]
    
    /// Mixed gradient for variety
    static let appMixedGradient2 = [
        appSecondary.opacity(0.5),
        appAccent.opacity(0.4)
    ]
}

