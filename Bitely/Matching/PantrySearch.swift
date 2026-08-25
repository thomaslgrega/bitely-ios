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

/// What the results area is showing.
enum PantrySearchState: Equatable {
    /// No search has been run yet.
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

    /// The ranked Matches, or `nil` when the state is not showing any.
    var matches: [RecipeMatch]? {
        guard case .matches(let matches) = state else { return nil }
        return matches
    }

    /// Searching a Pantry with nothing in it is malformed rather than empty
    /// (ADR-0003), so the interface asks for a food first.
    var canSearch: Bool { !pantryItems.isEmpty }

    /// Turns the draft into a Pantry Item. A blank names no food, and a food
    /// already entered adds nothing, so both leave the list alone.
    func commitDraft() {
        let item = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !item.isEmpty else { return }

        draft = ""
        guard !pantryItems.contains(where: { $0.caseInsensitiveCompare(item) == .orderedSame })
        else { return }

        pantryItems.append(item)
    }

    func remove(_ item: String) {
        pantryItems.removeAll { $0 == item }
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
}
