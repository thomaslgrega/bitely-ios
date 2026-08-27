import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Bitely

/// A one-pixel PNG, so `photo` cases run against data `UIImage` actually decodes.
private func onePixelPNG() -> Data {
    UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).pngData { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    }
}

@Suite("Design system components")
struct DesignSystemComponentTests {

    // MARK: - RecipeThumbnail

    @Test("stored image data wins over a thumbnail URL")
    func photoBeatsRemote() {
        let data = onePixelPNG()

        let source = ThumbnailSource(
            imageData: data,
            thumbnailURL: "https://example.com/pot-roast.jpg",
            category: .beef
        )

        #expect(source == .photo(data))
    }

    @Test("a thumbnail URL is used when there is no stored image")
    func remoteWhenNoPhoto() throws {
        let source = ThumbnailSource(
            imageData: nil,
            thumbnailURL: "https://example.com/pot-roast.jpg",
            category: .beef
        )

        #expect(source == .remote(try #require(URL(string: "https://example.com/pot-roast.jpg"))))
    }

    @Test("no photo and no URL falls back to the category tint")
    func tintWhenNeitherSource() {
        #expect(ThumbnailSource(imageData: nil, thumbnailURL: nil, category: .seafood)
                == .categoryTint(.seafood))
    }

    @Test(
        "a malformed thumbnail URL falls back to the category tint",
        arguments: ["", "   ", "not a url", "http://", "/relative/path.jpg"]
    )
    func tintWhenURLIsMalformed(thumbnailURL: String) {
        #expect(ThumbnailSource(imageData: nil, thumbnailURL: thumbnailURL, category: .pasta)
                == .categoryTint(.pasta))
    }

    @Test("image data that is not an image falls through to the remaining sources")
    func undecodableImageDataFallsThrough() {
        let junk = Data("not an image".utf8)

        #expect(ThumbnailSource(imageData: junk, thumbnailURL: nil, category: .dessert)
                == .categoryTint(.dessert))
    }

    // MARK: - SaveButton

    @Test("the control reports the saved state it is given", arguments: [true, false])
    func controlReportsSavedState(isSaved: Bool) {
        let control = SaveControl(isSaved: isSaved)

        #expect(control.isSaved == isSaved)
        #expect(control.symbolName == (isSaved ? "heart.fill" : "heart"))
    }

    @Test("saving takes one tap")
    func savingIsOneTap() {
        #expect(SaveControl(isSaved: false).tap == .save)
    }

    /// The heart deletes a local Recipe whose ingredients and instructions may have been
    /// edited, so a single tap must never be able to unsave — design-system.md, SaveButton.
    @Test("unsaving asks for confirmation rather than unsaving on the tap")
    func unsavingConfirmsFirst() {
        #expect(SaveControl(isSaved: true).tap == .confirmUnsave)
    }

    @Test("the two states read differently to VoiceOver")
    func savedStateIsAnnounced() {
        #expect(SaveControl(isSaved: true).accessibilityLabel
                != SaveControl(isSaved: false).accessibilityLabel)
    }

    // MARK: - SelectionIndicator

    @Test("a picked row reads as filled and an unpicked one as empty", arguments: [true, false])
    func selectionSymbol(isSelected: Bool) {
        let state = SelectionState(isSelected: isSelected)

        #expect(state.symbolName == (isSelected ? "checkmark.circle.fill" : "circle"))
    }

    /// The indicator carries no label of its own — the row's text is the label — so the
    /// only thing separating the two states for VoiceOver is the trait.
    @Test("only the picked state carries the selected trait", arguments: [true, false])
    func selectionTrait(isSelected: Bool) {
        #expect(SelectionState(isSelected: isSelected).traits.contains(.isSelected) == isSelected)
    }

    @Test("the picked state is the only one drawn in accent")
    func selectionTint() {
        #expect(SelectionState(isSelected: true).tint == .accent)
        #expect(SelectionState(isSelected: false).tint == .contentSecondary)
    }

    // MARK: - MetaLabel

    @Test("cook time and calories carry their units")
    func metaLabelText() {
        #expect(MetaLabel.cookTime(minutes: 35)?.text == "35 min")
        #expect(MetaLabel.calories(640)?.text == "640 cal")
    }

    @Test("a meta label with nothing to say is not shown")
    func metaLabelOmitsMissingValues() {
        #expect(MetaLabel.cookTime(minutes: nil) == nil)
        #expect(MetaLabel.calories(nil) == nil)
    }

    // MARK: - RecipeGrid

    @Test(
        "recipe grids are two columns up to the accessibility sizes",
        arguments: [DynamicTypeSize.xSmall, .large, .xxxLarge]
    )
    func twoColumnsBelowAccessibilitySizes(size: DynamicTypeSize) {
        #expect(RecipeGridLayout.columnCount(for: size) == 2)
    }

    @Test(
        "recipe grids collapse to one column at the accessibility sizes",
        arguments: [DynamicTypeSize.accessibility1, .accessibility3, .accessibility5]
    )
    func oneColumnAtAccessibilitySizes(size: DynamicTypeSize) {
        #expect(RecipeGridLayout.columnCount(for: size) == 1)
    }

    /// Every grid in the app defers here, so the whole scale is walked rather than the
    /// handful of sizes a caller happened to think of.
    @Test("the collapse happens at .accessibility1 and nowhere else", arguments: DynamicTypeSize.allCases)
    func collapseBoundary(size: DynamicTypeSize) {
        #expect(RecipeGridLayout.columnCount(for: size) == (size >= .accessibility1 ? 1 : 2))
    }
}
