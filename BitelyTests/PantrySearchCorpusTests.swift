//
//  Merging the corpus pass into the local one. Ranking itself belongs to
//  `IngredientMatcherTests`; what is asserted here is that the two ranked lists
//  become one, that a Saved Recipe survives the merge exactly once, and that
//  losing the corpus narrows the results rather than failing the search.
//

import Foundation
import Testing
@testable import Bitely

// MARK: - Fixtures

private func recipe(_ id: String, _ name: String, _ ingredients: String...) -> MatchableRecipe {
    MatchableRecipe(id: id, name: name, ingredientNames: ingredients)
}

/// A Match as the corpus reports one, built from the two Ingredient lists the
/// wire carries rather than from counts.
private func corpusMatch(
    _ id: String,
    _ name: String,
    has: [String],
    missing: [String] = []
) -> RecipeMatch {
    RecipeMatch(
        recipeID: id,
        recipeName: name,
        matchedCount: has.count,
        totalCount: has.count + missing.count,
        missingIngredients: missing
    )
}

private let pancakes = recipe("local-1", "Pancakes", "flour", "eggs", "milk", "butter")

@Suite("Pantry search — merging the corpus")
struct PantrySearchCorpusTests {

    /// Enters `items` and runs the search the interface runs.
    private func search(
        for items: [String],
        in recipes: [MatchableRecipe] = [],
        localIdentities: Set<String> = [],
        corpus: StubCorpus
    ) async -> PantrySearch {
        let search = PantrySearch()
        for item in items {
            search.draft = item
            search.commitDraft()
        }
        await search.search(in: recipes, localIdentities: localIdentities, corpus: corpus)
        return search
    }

    /// The merged Matches on show, or `nil` when the search is showing something else.
    private func merged(_ search: PantrySearch) -> [PantryMatch]? {
        guard case .matches(let matches) = search.state else { return nil }
        return matches
    }

    // MARK: - One list

    @Test("Shared Recipes from the corpus appear beside the local ones")
    func corpusMatchesJoinLocalOnes() async throws {
        let corpus = StubCorpus.matching([
            corpusMatch("corpus-1", "Shakshuka", has: ["eggs"], missing: ["tomatoes", "peppers"])
        ])
        let search = await search(for: ["eggs", "butter"], in: [pancakes], corpus: corpus)

        let matches = try #require(merged(search))
        #expect(matches.map(\.match.recipeName).sorted() == ["Pancakes", "Shakshuka"])
        #expect(matches.map(\.source).contains(.corpus))
        #expect(matches.map(\.source).contains(.local))
    }

    @Test("The merged list is one ordering, not two lists stapled together")
    func mergedByCoverageNotBySource() async throws {
        // Coverage 1/1 from the corpus outranks the local 2/4, and the local
        // 2/4 outranks the corpus 1/4.
        let corpus = StubCorpus.matching([
            corpusMatch("corpus-1", "Buttered Toast", has: ["butter"]),
            corpusMatch("corpus-2", "Custard", has: ["eggs"], missing: ["cream", "vanilla", "sugar"]),
        ])
        let search = await search(for: ["eggs", "butter"], in: [pancakes], corpus: corpus)

        let matches = try #require(merged(search))
        #expect(matches.map(\.match.recipeName) == ["Buttered Toast", "Pancakes", "Custard"])
    }

    @Test("A corpus Match is keyed by its corpus id, so tapping it opens the Shared Recipe")
    func corpusMatchKeepsItsCorpusID() async throws {
        let corpus = StubCorpus.matching([corpusMatch("corpus-1", "Shakshuka", has: ["eggs"])])
        let search = await search(for: ["eggs"], corpus: corpus)

        let match = try #require(merged(search)?.first)
        #expect(match.source == .corpus)
        #expect(match.id == "corpus-1")
    }

    // MARK: - A Saved Recipe is one Recipe

    @Test("A Saved Recipe matched on both sides appears once, as the local copy")
    func savedRecipeAppearsOnce() async throws {
        let saved = recipe("local-1", "Shakshuka", "eggs", "tomatoes")
        let corpus = StubCorpus.matching([
            corpusMatch("corpus-1", "Shakshuka", has: ["eggs"], missing: ["tomatoes"])
        ])
        let search = await search(
            for: ["eggs"],
            in: [saved],
            localIdentities: ["corpus-1"],
            corpus: corpus
        )

        let matches = try #require(merged(search))
        #expect(matches.count == 1)
        #expect(matches[0].source == .local)
        #expect(matches[0].id == "local-1")
    }

    @Test("A Saved Recipe is recognized by its own id as well as the corpus id")
    func savedRecipeMatchedByLocalID() async throws {
        let saved = recipe("local-1", "Shakshuka", "eggs", "tomatoes")
        let corpus = StubCorpus.matching([
            corpusMatch("local-1", "Shakshuka", has: ["eggs"], missing: ["tomatoes"])
        ])
        let search = await search(
            for: ["eggs"],
            in: [saved],
            localIdentities: ["local-1"],
            corpus: corpus
        )

        #expect(try #require(merged(search)).count == 1)
    }

    @Test("A Shared Recipe the user has not saved is not deduplicated away")
    func unsavedCorpusMatchSurvives() async throws {
        let corpus = StubCorpus.matching([corpusMatch("corpus-9", "Shakshuka", has: ["eggs"])])
        let search = await search(
            for: ["eggs"],
            in: [pancakes],
            localIdentities: ["local-1", "corpus-1"],
            corpus: corpus
        )

        #expect(try #require(merged(search)).count == 2)
    }

    // MARK: - What goes up

    @Test("Pantry Items reach the corpus exactly as the user typed them")
    func sendsRawPantryItems() async {
        let corpus = StubCorpus.matching([])
        _ = await search(for: ["2 Cups of FLOUR", "  Large Eggs "], in: [pancakes], corpus: corpus)

        #expect(corpus.lastPantryItems == ["2 Cups of FLOUR", "Large Eggs"])
    }

    @Test("A search with no Pantry Items entered never reaches the corpus")
    func emptyPantryDoesNotCallTheCorpus() async {
        let corpus = StubCorpus.matching([])
        let search = PantrySearch()

        await search.search(in: [pancakes], localIdentities: [], corpus: corpus)

        #expect(search.state == .idle)
        #expect(corpus.lastPantryItems == nil)
    }

    // MARK: - Losing the corpus

    @Test("Losing the corpus narrows the results rather than failing the search")
    func offlineKeepsLocalMatches() async throws {
        let search = await search(for: ["eggs", "butter"], in: [pancakes], corpus: .unreachable())

        let matches = try #require(merged(search))
        #expect(matches.map(\.match.recipeName) == ["Pancakes"])
        #expect(search.localOnly)
    }

    @Test("An API failure that is not a lost network degrades the same way")
    func apiErrorKeepsLocalMatches() async throws {
        let failure = StubCorpus.unreachable(APIError(statusCode: 500, body: nil))
        let search = await search(for: ["eggs", "butter"], in: [pancakes], corpus: failure)

        #expect(try #require(merged(search)).count == 1)
        #expect(search.localOnly)
    }

    @Test("An unreachable corpus with nothing local is an empty state, not an error")
    func offlineWithNoLocalMatchesIsEmpty() async {
        let search = await search(for: ["saffron"], in: [pancakes], corpus: .unreachable())

        #expect(search.state == .noMatches)
        #expect(search.localOnly)
    }

    @Test("A corpus that answers leaves the results unqualified")
    func reachableCorpusIsNotLocalOnly() async {
        let corpus = StubCorpus.matching([corpusMatch("corpus-1", "Shakshuka", has: ["eggs"])])
        let search = await search(for: ["eggs"], in: [pancakes], corpus: corpus)

        #expect(!search.localOnly)
    }

    @Test("Searching again after the corpus comes back drops the local-only notice")
    func localOnlyIsPerSearch() async {
        let search = await search(for: ["eggs"], in: [pancakes], corpus: .unreachable())
        #expect(search.localOnly)

        await search.search(in: [pancakes], localIdentities: [], corpus: StubCorpus.matching([]))

        #expect(!search.localOnly)
    }

    @Test("An answer for a Pantry the user has since changed is discarded")
    func staleAnswerIsDiscarded() async {
        let corpus = StubCorpus.matching([corpusMatch("corpus-1", "Shakshuka", has: ["eggs"])])
        let search = PantrySearch()
        search.draft = "eggs"
        search.commitDraft()

        corpus.duringSearch = { search.remove("eggs") }
        await search.search(in: [pancakes], corpus: corpus)

        #expect(search.state == .idle)
    }

    @Test("Changing the Pantry retires the local-only notice with the Matches")
    func editingThePantryRetiresTheNotice() async {
        let search = await search(for: ["eggs"], in: [pancakes], corpus: .unreachable())

        search.draft = "flour"
        search.commitDraft()

        #expect(search.state == .idle)
        #expect(!search.localOnly)
    }
}
