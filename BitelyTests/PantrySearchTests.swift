//
//  PantrySearchTests.swift
//  BitelyTests
//
//  The Pantry Item entry list and the search it runs over local Recipes.
//  Ranking and normalization themselves belong to `IngredientMatcherTests`;
//  what is asserted here is that the search hands the matcher what the user
//  typed and reports what comes back.
//

import Foundation
import Testing
@testable import Bitely

// MARK: - Fixtures

private func recipe(_ id: String, _ name: String, _ ingredients: String...) -> MatchableRecipe {
    MatchableRecipe(id: id, name: name, ingredientNames: ingredients)
}

/// The ranked Matches on show, or `nil` when the search is showing something else.
private func rankedMatches(of search: PantrySearch) -> [RecipeMatch]? {
    guard case .matches(let matches) = search.state else { return nil }
    return matches
}

private let pancakes = recipe("1", "Pancakes", "flour", "eggs", "milk", "butter")
private let omelette = recipe("2", "Omelette", "eggs", "butter")
private let cassoulet = recipe(
    "3", "Cassoulet",
    "duck legs", "pork belly", "sausage", "haricot beans", "carrot", "onion",
    "garlic", "tomato paste", "thyme", "bay leaf", "chicken stock", "breadcrumbs"
)

// MARK: - Entering Pantry Items

@Suite("Pantry search — entering Pantry Items")
struct PantryItemEntryTests {

    @Test("A committed draft becomes a Pantry Item and clears the field")
    func commitAddsItem() {
        let search = PantrySearch()
        search.draft = "eggs"
        search.commitDraft()

        #expect(search.pantryItems == ["eggs"])
        #expect(search.draft.isEmpty)
    }

    @Test("Several foods can be entered and searched together")
    func multipleItems() {
        let search = PantrySearch()
        for food in ["eggs", "butter", "flour"] {
            search.draft = food
            search.commitDraft()
        }

        #expect(search.pantryItems == ["eggs", "butter", "flour"])
    }

    @Test("Surrounding whitespace is trimmed")
    func trimsWhitespace() {
        let search = PantrySearch()
        search.draft = "  eggs \n"
        search.commitDraft()

        #expect(search.pantryItems == ["eggs"])
    }

    @Test("A blank draft names no food and is not a Pantry Item", arguments: ["", "   ", "\n"])
    func blankDraftIgnored(draft: String) {
        let search = PantrySearch()
        search.draft = draft
        search.commitDraft()

        #expect(search.pantryItems.isEmpty)
        #expect(!search.canSearch)
    }

    @Test("The same food entered twice is kept once, whatever the casing")
    func duplicatesIgnored() {
        let search = PantrySearch()
        for food in ["Eggs", "eggs", "  EGGS  "] {
            search.draft = food
            search.commitDraft()
        }

        #expect(search.pantryItems == ["Eggs"])
    }

    @Test("A Pantry Item can be removed")
    func removeItem() {
        let search = PantrySearch()
        for food in ["eggs", "butter"] {
            search.draft = food
            search.commitDraft()
        }
        search.remove("eggs")

        #expect(search.pantryItems == ["butter"])
    }

    @Test("Removing a Pantry Item ignores casing, as entering one does")
    func removeIgnoresCasing() {
        let search = PantrySearch()
        search.draft = "Eggs"
        search.commitDraft()
        search.remove("eggs")

        #expect(search.pantryItems.isEmpty)
    }

    @Test("Searching needs at least one Pantry Item")
    func canSearchNeedsAnItem() {
        let search = PantrySearch()
        #expect(!search.canSearch)

        search.draft = "eggs"
        search.commitDraft()
        #expect(search.canSearch)
    }

    @Test("A blank draft is not committable")
    func canCommitNeedsAFood() {
        let search = PantrySearch()
        #expect(!search.canCommit)

        search.draft = "   "
        #expect(!search.canCommit)

        search.draft = " eggs "
        #expect(search.canCommit)
    }
}

// MARK: - Searching

@Suite("Pantry search — Matches")
struct PantrySearchMatchTests {

    /// Enters `items` and searches `recipes`, which is what the interface does.
    private func search(
        for items: [String],
        in recipes: [MatchableRecipe]
    ) -> PantrySearch {
        let search = PantrySearch()
        for item in items {
            search.draft = item
            search.commitDraft()
        }
        search.search(in: recipes)
        return search
    }

    @Test("Nothing has been searched for yet")
    func startsIdle() {
        #expect(PantrySearch().state == .idle)
    }

    @Test("Searching with no Pantry Items entered does not run a search")
    func emptyPantryDoesNotSearch() {
        let search = PantrySearch()
        search.search(in: [pancakes])

        #expect(search.state == .idle)
    }

    @Test("A Match reports the Coverage and the Missing Ingredients")
    func reportsCoverageAndMissing() throws {
        let search = search(for: ["eggs", "butter"], in: [pancakes])
        let matches = try #require(rankedMatches(of: search))
        let match = try #require(matches.first)

        #expect(match.recipeName == "Pancakes")
        #expect(match.matchedCount == 2)
        #expect(match.totalCount == 4)
        #expect(match.missingIngredients == ["flour", "milk"])
    }

    @Test("An incomplete Match still appears, ranked below a fuller one")
    func incompleteMatchesRankBelow() throws {
        let search = search(for: ["eggs", "butter"], in: [pancakes, omelette])
        let matches = try #require(rankedMatches(of: search))

        #expect(matches.map(\.recipeName) == ["Omelette", "Pancakes"])
        #expect(matches[1].missingIngredients == ["flour", "milk"])
    }

    @Test("A twelve-Ingredient Recipe missing three outranks a four-Ingredient Recipe missing three")
    func coverageOutranksMissingCount() throws {
        let search = search(
            for: [
                "duck legs", "pork belly", "sausage", "haricot beans", "carrot",
                "onion", "garlic", "tomato paste", "thyme", "eggs",
            ],
            in: [cassoulet, pancakes]
        )
        let matches = try #require(rankedMatches(of: search))

        #expect(matches.map(\.recipeName) == ["Cassoulet", "Pancakes"])
        #expect(matches[0].missingIngredients.count == 3)
        #expect(matches[1].missingIngredients.count == 3)
    }

    @Test(
        "A food entered naturally still matches",
        arguments: ["2 cups of Flour", "FLOUR", "  flour, sifted  ", "500g flour"]
    )
    func naturalEntryMatches(item: String) throws {
        let search = search(for: [item], in: [pancakes])
        let matches = try #require(rankedMatches(of: search))

        #expect(matches.count == 1)
        #expect(matches[0].missingIngredients == ["eggs", "milk", "butter"])
    }

    @Test("A Pantry that covers nothing is an empty state, not an error")
    func noMatchesIsEmptyState() {
        let search = search(for: ["saffron"], in: [pancakes, omelette])

        #expect(search.state == .noMatches)
        #expect(rankedMatches(of: search) == nil)
    }

    @Test("Searching again replaces the previous Matches")
    func searchingAgainReplacesMatches() throws {
        let search = search(for: ["eggs"], in: [pancakes, omelette])
        #expect(try #require(rankedMatches(of: search)).count == 2)

        search.remove("eggs")
        search.draft = "saffron"
        search.commitDraft()
        search.search(in: [pancakes, omelette])

        #expect(search.state == .noMatches)
    }

    @Test("Entering another Pantry Item retires Matches found without it")
    func addingAnItemClearsMatches() {
        let search = search(for: ["eggs"], in: [pancakes, omelette])

        search.draft = "flour"
        search.commitDraft()

        #expect(search.state == .idle)
    }

    @Test("Removing a Pantry Item retires Matches found with it")
    func removingAnItemClearsMatches() {
        let search = search(for: ["eggs", "flour"], in: [pancakes, omelette])

        search.remove("flour")

        #expect(search.state == .idle)
    }

    @Test("Pantry Items are search input only — a new search starts empty")
    func pantryItemsAreEphemeral() {
        let first = PantrySearch()
        first.draft = "eggs"
        first.commitDraft()
        first.search(in: [pancakes])

        let second = PantrySearch()
        #expect(second.pantryItems.isEmpty)
        #expect(second.state == .idle)
    }
}

// MARK: - Local Recipes

@Suite("Pantry search — local Recipes")
struct MatchableRecipeFromLocalRecipeTests {

    @Test("A local Recipe is matched by its Ingredient names, in Recipe order")
    func mapsLocalRecipe() {
        let stored = Recipe(
            name: "Omelette",
            category: .breakfast,
            ingredients: [
                Ingredient(name: "eggs", measurement: "3"),
                Ingredient(name: "butter", measurement: "1 tbsp"),
            ]
        )

        let matchable = MatchableRecipe(stored)

        #expect(matchable.id == stored.id.uuidString)
        #expect(matchable.name == "Omelette")
        #expect(matchable.ingredientNames == ["eggs", "butter"])
    }
}
