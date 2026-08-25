//
//  PantrySearch.swift
//  Bitely
//
//  One search over the Recipes held on this device: the Pantry Items the user
//  has typed so far, and the Matches they produced.
//
//  Pantry Items are search input, not a pantry the user keeps. Nothing here
//  reaches SwiftData or `UserDefaults`, so they live exactly as long as the
//  screen does.
//
//  Ranking, normalization and Coverage belong to `IngredientMatcher`, which is
//  the port of the shared algorithm; this type does no comparison of its own.
//

import Foundation

/// What the search has to show.
enum PantrySearchState: Equatable {
    /// No search has been run against the Pantry as it currently stands.
    case idle
    /// Matches, already ranked best fit first.
    case matches([RecipeMatch])
    /// A search ran and the Pantry covered no Recipe on this device.
    case noMatches
}

@Observable
final class PantrySearch {

    /// The food being typed, bound to the entry field. It is not a Pantry Item
    /// until it is committed.
    var draft: String = ""

    /// The Pantry Items entered so far, in entry order, as the user wrote them.
    private(set) var pantryItems: [String] = []

    private(set) var state: PantrySearchState = .idle

    /// Whether the draft names a food yet.
    var canCommit: Bool { !trimmedDraft.isEmpty }

    /// Searching a Pantry with nothing in it is malformed rather than empty
    /// (ADR-0003), so the interface asks for a food first.
    var canSearch: Bool { !pantryItems.isEmpty }

    /// Turns the draft into a Pantry Item. A blank names no food, and a food
    /// already entered adds nothing, so both leave the list alone.
    func commitDraft() {
        let item = trimmedDraft
        guard canCommit else { return }

        draft = ""
        guard !pantryItems.contains(where: { matchesItem($0, item) }) else { return }

        pantryItems.append(item)
        retireMatches()
    }

    /// Drops a Pantry Item, by the same equality that kept it out as a
    /// duplicate: a food entered as `Eggs` is the one a chip reading `Eggs`
    /// removes, whatever case the caller passes.
    func remove(_ item: String) {
        pantryItems.removeAll { matchesItem($0, item) }
        retireMatches()
    }

    /// Matches the entered Pantry Items against `recipes` and keeps the result.
    ///
    /// A Pantry that covers nothing is `.noMatches`, not a failure: the only
    /// error the matcher raises is the blank Pantry the interface already
    /// prevents, and it leaves the results as they were.
    func search(in recipes: [MatchableRecipe]) {
        guard let matches = try? IngredientMatcher.match(
            pantryItems: pantryItems,
            recipes: recipes
        ) else { return }

        state = matches.isEmpty ? .noMatches : .matches(matches)
    }

    // MARK: - Details

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Pantry Items name the same food when they differ only by case: the user
    /// typed a food, not a spelling.
    private func matchesItem(_ lhs: String, _ rhs: String) -> Bool {
        lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }

    /// Matches describe the Pantry they were found for. Once that Pantry
    /// changes they are stale — showing them beside the new Pantry Items would
    /// claim a Coverage nobody computed — so the search goes back to idle and
    /// the user runs it again.
    private func retireMatches() {
        state = .idle
    }
}
