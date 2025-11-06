//
//  BrandStyle.swift
//  Spark
//
//  Shared brand colors and fonts
//

import SwiftUI

// MARK: - Brand Colors

extension Color {
    static let brandDominant = Color("dominant")
    static let brandAccent = Color("accent")
    static let brandSecondary = Color("secondary")
}

// MARK: - Brand Fonts

enum SparkFont {
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    static func logo(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

