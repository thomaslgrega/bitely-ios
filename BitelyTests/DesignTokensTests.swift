import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Bitely

/// Hex of a named color resolved in one appearance, or nil if the catalog has no such entry.
private func resolvedHex(_ assetName: String, _ style: UIUserInterfaceStyle) -> String? {
    guard let color = UIColor(named: assetName) else { return nil }
    let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
    return String(format: "#%02X%02X%02X", Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
}

@Suite("Design tokens")
struct DesignTokensTests {

    // MARK: - Role tokens

    /// No token in this system is meant to be appearance-independent, so two appearances
    /// resolving to one value is how an unfilled dark column shows up.
    @Test("every role token resolves in both appearances", arguments: ColorToken.allCases)
    func roleTokenResolves(token: ColorToken) throws {
        let light = try #require(resolvedHex(token.assetName, .light))
        let dark = try #require(resolvedHex(token.assetName, .dark))

        #expect(light != dark, "\(token.assetName) has no dark appearance of its own")
    }

    @Test(
        "the brand palette carries the values the design system specifies",
        arguments: [
            ("Brand/cream", "#FFFBF7"),
            ("Brand/ink", "#24211D"),
            ("Brand/inkSoft", "#6B655C"),
            ("Brand/red", "#932D2C"),
            ("Brand/hairline", "#E8E0D6"),
        ]
    )
    func brandValue(assetName: String, hex: String) {
        #expect(resolvedHex(assetName, .light) == hex)
    }

    /// The catalog has no color-to-color reference, so each role token restates the brand
    /// value it carries. This is what keeps the two copies honest.
    @Test(
        "role tokens carry the brand value the design system assigns them",
        arguments: [
            (ColorToken.surface, "Brand/cream"),
            (.surfaceInverse, "Brand/ink"),
            (.contentPrimary, "Brand/ink"),
            (.contentSecondary, "Brand/inkSoft"),
            (.contentOnInverse, "Brand/cream"),
            (.accent, "Brand/red"),
            (.border, "Brand/hairline"),
        ]
    )
    func roleTokenCarriesBrandValue(token: ColorToken, brand: String) {
        #expect(resolvedHex(token.assetName, .light) == resolvedHex(brand, .light))
    }

    @Test(
        "the role tokens outside the brand palette carry their specified values",
        arguments: [(ColorToken.surfaceRaised, "#FFFFFF"), (.destructive, "#C0392B")]
    )
    func roleTokenLightValue(token: ColorToken, hex: String) {
        #expect(resolvedHex(token.assetName, .light) == hex)
    }

    @Test("accent and destructive are distinguishable")
    func accentIsNotDestructive() {
        #expect(resolvedHex(ColorToken.accent.assetName, .light)
                != resolvedHex(ColorToken.destructive.assetName, .light))
    }

    // MARK: - Category tints

    @Test("every category resolves to a tint in both appearances", arguments: FoodCategory.allCases)
    func categoryTintResolves(category: FoodCategory) throws {
        let light = try #require(resolvedHex(category.tintAssetName, .light))
        let dark = try #require(resolvedHex(category.tintAssetName, .dark))

        #expect(light != dark, "\(category.tintAssetName) has no dark appearance of its own")
    }

    @Test(
        "category tints carry the values the design system specifies",
        arguments: [
            (FoodCategory.beef, "#E9C8C0"),
            (.breakfast, "#F1DFC8"),
            (.chicken, "#F0DCC0"),
            (.dessert, "#EBD3DA"),
            (.pasta, "#F2E1BC"),
            (.pork, "#E7CBC7"),
            (.seafood, "#C9DBE2"),
            (.side, "#D6DFC8"),
            (.vegetarian, "#CDDCC6"),
            (.other, "#DDD8CE"),
        ]
    )
    func categoryTintLightValue(category: FoodCategory, hex: String) {
        #expect(resolvedHex(category.tintAssetName, .light) == hex)
    }

    @Test("an unrecognized category falls back to Other's tint")
    func unknownCategoryTint() {
        #expect(FoodCategory(apiValue: "Souffle").tintAssetName == FoodCategory.other.tintAssetName)
    }

    // MARK: - Type

    @Test("Fraunces resolves to the bundled face rather than the system font", arguments: Fraunces.allCases)
    func frauncesIsRegistered(face: Fraunces) throws {
        let font = try #require(UIFont(name: face.rawValue, size: 16))

        #expect(font.familyName == "Fraunces")
    }

    @Test(
        "the type scale matches the design system",
        arguments: [
            (TypeToken.display, TypeSpec(face: .fraunces(.semiBold), size: 30, textStyle: .title)),
            (.sectionTitle, TypeSpec(face: .fraunces(.semiBold), size: 24, textStyle: .title2)),
            (.greeting, TypeSpec(face: .fraunces(.semiBold), size: 19, textStyle: .title3)),
            (.cardTitle, TypeSpec(face: .fraunces(.semiBold), size: 16, textStyle: .headline)),
            (.body, TypeSpec(face: .system(.regular), size: 15, textStyle: .body)),
            (.meta, TypeSpec(face: .system(.regular), size: 13, textStyle: .footnote)),
            (.label, TypeSpec(face: .system(.semibold), size: 14, textStyle: .subheadline)),
        ]
    )
    func typeScale(token: TypeToken, spec: TypeSpec) {
        #expect(token.spec == spec)
    }
}
