//
//  BrandStyle.swift
//  Spark
//
//  Shared brand colors and fonts
//

// A skeleton starter code for this page was AI generated

import SwiftUI

extension Color {
    static let brandDominant = Color("dominant")
    static let brandAccent = Color("accent")
    static let brandSecondary = Color("secondary")

    static let brandBackground = Color("background")
    static let brandCard = Color("card")
    static let brandTextPrimary = Color("textPrimary")
    static let brandTextSecondary = Color("textSecondary")
}


enum SparkFont {
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func logo(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

enum BrandStyle {
    static let background = Color.brandBackground
    static let card = Color.brandCard
    static let primary = Color.brandDominant
    static let accent = Color.brandAccent
    static let secondary = Color.brandSecondary
    static let textPrimary = Color.brandTextPrimary
    static let textSecondary = Color.brandTextSecondary

    // Fonts
    static let title = SparkFont.ui(22, weight: .semibold)
    static let body = SparkFont.ui(16)
    static let caption = SparkFont.ui(13)
    static let button = SparkFont.ui(17, weight: .medium)
    static let sectionTitle = SparkFont.ui(19, weight: .semibold)
}

extension Notification.Name {
    static let resetCreateFlow = Notification.Name("resetCreateFlow")
}
