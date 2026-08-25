//
//  One search over every Recipe the user could reach: the Pantry Items they
//  have typed so far, and the Matches those produced on this device and in the
//  corpus, merged into a single ranked list.
//
//  Pantry Items are search input, not a pantry the user keeps. Nothing here
//  reaches SwiftData or `UserDefaults`, so they live exactly as long as the
//  screen does.
//
//  Ranking, normalization and Coverage belong to `IngredientMatcher`, which is
//  the port of the shared algorithm; this type does no comparison of its own,
//  and merging the two lists belongs to `PantryMatch`.
//

import Foundation

/// The corpus half of the search: the API's pass over Shared Recipes.
/// `RecipeService` provides it in the app; tests substitute.
protocol CorpusMatching {
    /// Matches Pantry Items against the corpus, raw and un-normalized: the
    /// endpoint normalizes them itself, and doing it here first would apply the
    /// rules twice.
    func matchCorpus(pantryItems: [String]) async throws -> [RecipeMatch]
}

/// What the search has to show.
enum PantrySearchState: Equatable {
    /// No search has been run against the Pantry as it currently stands.
    case idle
    /// The corpus has been asked and has not answered yet.
    case searching
    /// Matches from both sides, merged and ranked best fit first.
    case matches([PantryMatch])
    /// A search ran and the Pantry covered nothing either side could offer.
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

    /// Whether the last search ran without the corpus, so the Matches on show
    /// are this device's Recipes alone. The interface says so: a user given a
    /// short list with no explanation concludes the feature is bad.
    private(set) var localOnly = false

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

    /// Matches the entered Pantry Items against `recipes` on this device and
    /// against the corpus, and keeps the merged result.
    ///
    /// A Pantry that covers nothing is `.noMatches`, not a failure: the only
    /// error the matcher raises is the blank Pantry the interface already
    /// prevents, and it leaves the results as they were.
    ///
    /// Losing the corpus narrows the results to this device rather than failing
    /// the search, and sets `localOnly`. The local pass has already run by then,
    /// so there is nothing to retry and nothing to report as an error.
    ///
    /// An answer that arrives for a Pantry the user has since changed is
    /// dropped.
    ///
    /// - Parameter localIdentities: the ids the local store answers to, so a
    ///   Saved Recipe is not offered twice. See `Recipe.matchIdentities`.
    func search(
        in recipes: [MatchableRecipe],
        localIdentities: Set<String> = [],
        corpus: any CorpusMatching
    ) async {
        guard let localMatches = try? IngredientMatcher.match(
            pantryItems: pantryItems,
            recipes: recipes
        ) else { return }

        let searched = pantryItems
        state = .searching

        var corpusMatches: [RecipeMatch] = []
        var reachedCorpus = true
        do {
            corpusMatches = try await corpus.matchCorpus(pantryItems: pantryItems)
        } catch {
            reachedCorpus = false
        }

        // The user can edit the Pantry while the corpus is answering, and
        // `retireMatches` has already put the search back to idle for them.
        // Matches describe the Pantry they were found for, so this answer is
        // dropped rather than shown beside Pantry Items nobody searched.
        guard pantryItems == searched else { return }

        let merged = PantryMatch.merge(
            local: localMatches,
            corpus: corpusMatches,
            localIdentities: localIdentities
        )

        localOnly = !reachedCorpus
        state = merged.isEmpty ? .noMatches : .matches(merged)
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
        localOnly = false
    }
}
