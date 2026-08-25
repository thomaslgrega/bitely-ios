import SwiftUI

/// The role colors views paint with. The brand values behind them (cream, ink, red) are
/// named only in `Assets.xcassets/Brand`, so a view cannot reach past the role it wants to
/// the value it happens to have today — ADR-0001. Brand entries carry one appearance each:
/// a role inverts in dark, the value it is named after does not.
enum ColorToken: String, CaseIterable {
    case surface
    case surfaceRaised
    case surfaceInverse
    case contentPrimary
    case contentSecondary
    case contentOnInverse
    case accent
    case destructive
    case border

    var assetName: String { "Tokens/\(rawValue)" }
}

extension Color {
    init(_ token: ColorToken) {
        self.init(token.assetName)
    }

    static let surface = Color(ColorToken.surface)
    static let surfaceRaised = Color(ColorToken.surfaceRaised)
    static let surfaceInverse = Color(ColorToken.surfaceInverse)
    static let contentPrimary = Color(ColorToken.contentPrimary)
    static let contentSecondary = Color(ColorToken.contentSecondary)
    static let contentOnInverse = Color(ColorToken.contentOnInverse)
    static let accent = Color(ColorToken.accent)
    static let destructive = Color(ColorToken.destructive)
    static let border = Color(ColorToken.border)
}

extension FoodCategory {
    /// The ground a recipe photo falls back to. Switched rather than interpolated from
    /// the raw value so a new category is a compile error, not a color that fails to load.
    var tintAssetName: String {
        switch self {
        case .beef: "Tints/beef"
        case .breakfast: "Tints/breakfast"
        case .chicken: "Tints/chicken"
        case .dessert: "Tints/dessert"
        case .other: "Tints/other"
        case .pasta: "Tints/pasta"
        case .pork: "Tints/pork"
        case .seafood: "Tints/seafood"
        case .side: "Tints/side"
        case .vegetarian: "Tints/vegetarian"
        }
    }

    var tint: Color { Color(tintAssetName) }
}
