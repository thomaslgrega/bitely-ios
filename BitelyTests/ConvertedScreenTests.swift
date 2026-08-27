import Foundation
import SwiftUI
import Testing
@testable import Bitely

@Suite("Converted screens")
struct ConvertedScreenTests {

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

    // MARK: - CoverageSummary

    @Test("a Match spells its Coverage out as the integer pair the matcher keeps")
    func coverageLine() {
        let summary = CoverageSummary(match: match(matched: 3, total: 5, missing: ["butter", "sage"]))

        #expect(summary.coverage == "You have 3 of 5 ingredients")
    }

    @Test("the Missing Ingredients are named, in the Recipe's own order")
    func missingLine() {
        let summary = CoverageSummary(match: match(matched: 1, total: 3, missing: ["butter", "sage"]))

        #expect(summary.missing == "Missing: butter, sage")
        #expect(summary.isComplete == false)
    }

    /// A complete Match is the one worth cooking tonight, so it says so rather than showing
    /// an empty Missing line.
    @Test("a Match the Pantry covers entirely reports completion instead of a missing list")
    func completeMatch() {
        let summary = CoverageSummary(match: match(matched: 4, total: 4, missing: []))

        #expect(summary.isComplete)
        #expect(summary.missing == nil)
    }

    private func match(matched: Int, total: Int, missing: [String]) -> RecipeMatch {
        RecipeMatch(
            recipeID: "1",
            recipeName: "Brown Butter Gnocchi",
            matchedCount: matched,
            totalCount: total,
            missingIngredients: missing
        )
    }
}
