//
//  Fixtures transcribed from section 6 of `docs/ingredient-matching-algorithm.md`
//  in the API repo (thomaslgrega/bitelyapi). That document is the source of
//  truth; every row here is an assertion it makes.
//

import Foundation
import Testing
@testable import Bitely

// MARK: - 6.1 Token-pair similarity

struct TokenPairFixture: CustomStringConvertible, Sendable {
    let a: String
    let b: String
    let countA: Int
    let countB: Int
    let intersection: Int
    let union: Int
    let matches: Bool

    var description: String { "\(a)/\(b)" }
}

@Suite("Ingredient matcher — token similarity")
struct TokenSimilarityTests {

    static let fixtures: [TokenPairFixture] = [
        .init(a: "tomato", b: "tomato", countA: 7, countB: 7, intersection: 7, union: 7, matches: true),
        .init(a: "tomato", b: "tomatoes", countA: 7, countB: 9, intersection: 6, union: 10, matches: true),
        .init(a: "onion", b: "onions", countA: 6, countB: 7, intersection: 5, union: 8, matches: true),
        .init(a: "breast", b: "breasts", countA: 7, countB: 8, intersection: 6, union: 9, matches: true),
        .init(a: "potato", b: "potatoes", countA: 7, countB: 9, intersection: 6, union: 10, matches: true),
        .init(a: "egg", b: "eggs", countA: 4, countB: 5, intersection: 3, union: 6, matches: true),
        .init(a: "oat", b: "oats", countA: 4, countB: 5, intersection: 3, union: 6, matches: true),
        .init(a: "mushroom", b: "mushrooms", countA: 9, countB: 10, intersection: 8, union: 11, matches: true),
        .init(a: "yogurt", b: "yoghurt", countA: 7, countB: 8, intersection: 5, union: 10, matches: true),
        // Boundary: exactly 0.3, and the comparison is >=, not >.
        .init(a: "egg", b: "eggplant", countA: 4, countB: 9, intersection: 3, union: 10, matches: true),
        .init(a: "rice", b: "ricotta", countA: 5, countB: 8, intersection: 3, union: 10, matches: true),
        // Section 7.1: expected to be a non-match, and is not.
        .init(a: "chicken", b: "chickpea", countA: 8, countB: 9, intersection: 5, union: 12, matches: true),
        .init(a: "chicken", b: "chickpeas", countA: 8, countB: 10, intersection: 5, union: 13, matches: true),
        .init(a: "chicken", b: "kitchen", countA: 8, countB: 8, intersection: 1, union: 15, matches: false),
        .init(a: "chicken", b: "chili", countA: 8, countB: 6, intersection: 3, union: 11, matches: false),
        .init(a: "tomato", b: "potato", countA: 7, countB: 7, intersection: 2, union: 12, matches: false),
        .init(a: "basil", b: "basmati", countA: 6, countB: 8, intersection: 3, union: 11, matches: false),
        .init(a: "lemon", b: "lime", countA: 6, countB: 5, intersection: 1, union: 10, matches: false),
        .init(a: "beef", b: "broth", countA: 5, countB: 6, intersection: 1, union: 10, matches: false),
        .init(a: "kale", b: "cake", countA: 5, countB: 5, intersection: 0, union: 10, matches: false),
        .init(a: "chicken", b: "stock", countA: 8, countB: 6, intersection: 0, union: 14, matches: false),
        .init(a: "yellow", b: "onion", countA: 7, countB: 6, intersection: 0, union: 13, matches: false),
        .init(a: "butter", b: "buttermilk", countA: 7, countB: 11, intersection: 6, union: 12, matches: true),
        // Suffix containment does not match — the asymmetry is inherited from pg_trgm.
        .init(a: "milk", b: "buttermilk", countA: 5, countB: 11, intersection: 3, union: 13, matches: false),
        .init(a: "bread", b: "breadcrumbs", countA: 6, countB: 12, intersection: 5, union: 13, matches: true),
        .init(a: "corn", b: "cornstarch", countA: 5, countB: 11, intersection: 4, union: 12, matches: true),
        .init(a: "apple", b: "pineapple", countA: 6, countB: 10, intersection: 4, union: 12, matches: true),
        .init(a: "pepper", b: "pepperoni", countA: 7, countB: 10, intersection: 6, union: 11, matches: true),
        .init(a: "pea", b: "peanut", countA: 4, countB: 7, intersection: 3, union: 8, matches: true),
        .init(a: "celery", b: "celeriac", countA: 7, countB: 9, intersection: 5, union: 11, matches: true),
        .init(a: "parsley", b: "parsnip", countA: 8, countB: 8, intersection: 4, union: 12, matches: true),
        .init(a: "onion", b: "union", countA: 6, countB: 6, intersection: 3, union: 9, matches: true),
        .init(a: "beef", b: "beets", countA: 5, countB: 6, intersection: 3, union: 8, matches: true),
    ]

    @Test("Trigram arithmetic matches the fixture table", arguments: fixtures)
    func trigramArithmetic(fixture: TokenPairFixture) {
        let a = IngredientMatcher.trigrams(of: fixture.a)
        let b = IngredientMatcher.trigrams(of: fixture.b)

        #expect(a.count == fixture.countA)
        #expect(b.count == fixture.countB)
        #expect(a.intersection(b).count == fixture.intersection)
        #expect(a.union(b).count == fixture.union)
    }

    @Test("Threshold verdicts match the fixture table", arguments: fixtures)
    func verdict(fixture: TokenPairFixture) {
        #expect(IngredientMatcher.tokensMatch(fixture.a, fixture.b) == fixture.matches)
        #expect(IngredientMatcher.tokensMatch(fixture.b, fixture.a) == fixture.matches)
    }

    @Test("Trigrams are a set, not a multiset")
    func trigramsDeduplicate() {
        // "banana" extracts `ana` twice; it contributes one element.
        #expect(IngredientMatcher.trigrams(of: "banana").count == 6)
        #expect(IngredientMatcher.tokensMatch("banana", "banana"))
    }

    @Test("Padding is two leading spaces and one trailing space")
    func padding() {
        #expect(IngredientMatcher.trigrams(of: "onion") == ["  o", " on", "oni", "nio", "ion", "on "])
    }

    @Test("MatchThreshold is 0.3")
    func threshold() {
        #expect(IngredientMatcher.matchThreshold == 0.3)
    }
}

// MARK: - 1. Normalization

@Suite("Ingredient matcher — normalization")
struct NormalizationTests {

    @Test("Normalization examples from section 1", arguments: [
        ("Tomatoes", ["tomatoes"]),
        ("  ToMaTo  ", ["tomato"]),
        ("2 Yellow Onions", ["yellow", "onions"]),
        ("Boneless, skinless chicken breasts", ["chicken", "breasts"]),
        ("1 1/2 cups all-purpose flour", ["all", "purpose", "flour"]),
        ("Salt & pepper, to taste", ["salt", "pepper"]),
        ("freshly chopped", []),
        ("", []),
        ("   ", []),
    ] as [(String, [String])])
    func examples(raw: String, expected: [String]) {
        #expect(IngredientMatcher.normalize(raw) == Set(expected))
    }

    @Test("Splitting happens before punctuation is stripped")
    func splitBeforeStrip() {
        // "fl.oz" must not fuse into "floz", nor "salt/pepper" into "saltpepper".
        #expect(IngredientMatcher.normalize("1 fl.oz vanilla") == ["vanilla"])
        #expect(IngredientMatcher.normalize("salt/pepper") == ["salt", "pepper"])
    }

    @Test("Digits are stripped from each token")
    func digitsStripped() {
        #expect(IngredientMatcher.normalize("500g Beef") == ["beef"])
        #expect(IngredientMatcher.normalize("2 1/2") == [])
    }

    @Test("Unicode fractions are boundaries, not digits")
    func unicodeFractions() {
        #expect(IngredientMatcher.normalize("½ cup ⅓ milk") == ["milk"])
    }

    @Test("Colour and variety words survive")
    func coloursSurvive() {
        #expect(IngredientMatcher.normalize("sweet potato") == ["sweet", "potato"])
        #expect(IngredientMatcher.normalize("green onion") == ["green", "onion"])
    }

    @Test("Stopword lists are named separately and hold their documented entries")
    func stopwordLists() {
        #expect(IngredientMatcher.measurementStopwords.contains("tbsp"))
        #expect(IngredientMatcher.measurementStopwords.contains("floz"))
        #expect(IngredientMatcher.measurementStopwords.contains("taste"))
        #expect(IngredientMatcher.measurementStopwords.contains("whole"))
        #expect(IngredientMatcher.descriptorStopwords.contains("boneless"))
        #expect(IngredientMatcher.descriptorStopwords.contains("skinless"))
        // Explicitly not stopwords.
        for food in ["salted", "sweetened", "fat", "cream", "stock", "broth", "sweet", "baby", "wild"] {
            #expect(!IngredientMatcher.measurementStopwords.contains(food), "\(food)")
            #expect(!IngredientMatcher.descriptorStopwords.contains(food), "\(food)")
        }
    }
}

// MARK: - 6.2 Pantry Item against Ingredient Term

struct TermPairFixture: CustomStringConvertible, Sendable {
    let pantry: String
    let ingredient: String
    let pantryTokens: [String]
    let ingredientTokens: [String]
    let matches: Bool

    var description: String { "\(pantry) / \(ingredient)" }
}

@Suite("Ingredient matcher — pantry item against ingredient term")
struct TermMatchingTests {

    static let fixtures: [TermPairFixture] = [
        .init(pantry: "tomato", ingredient: "tomato", pantryTokens: ["tomato"], ingredientTokens: ["tomato"], matches: true),
        .init(pantry: "Tomato", ingredient: "tomato", pantryTokens: ["tomato"], ingredientTokens: ["tomato"], matches: true),
        .init(pantry: "  ToMaTo  ", ingredient: "Tomato", pantryTokens: ["tomato"], ingredientTokens: ["tomato"], matches: true),
        .init(pantry: "tomato", ingredient: "Tomatoes", pantryTokens: ["tomato"], ingredientTokens: ["tomatoes"], matches: true),
        .init(pantry: "Tomatoes", ingredient: "1 tomato, diced", pantryTokens: ["tomatoes"], ingredientTokens: ["tomato"], matches: true),
        .init(pantry: "chicken breast", ingredient: "boneless skinless chicken breasts",
              pantryTokens: ["chicken", "breast"], ingredientTokens: ["chicken", "breasts"], matches: true),
        .init(pantry: "chicken breast", ingredient: "Boneless, Skinless Chicken Breasts",
              pantryTokens: ["chicken", "breast"], ingredientTokens: ["chicken", "breasts"], matches: true),
        .init(pantry: "2 Yellow Onions", ingredient: "onion",
              pantryTokens: ["yellow", "onions"], ingredientTokens: ["onion"], matches: true),
        .init(pantry: "1 1/2 cups all-purpose flour", ingredient: "Flour",
              pantryTokens: ["all", "purpose", "flour"], ingredientTokens: ["flour"], matches: true),
        .init(pantry: "½ cup ⅓ milk", ingredient: "Milk", pantryTokens: ["milk"], ingredientTokens: ["milk"], matches: true),
        .init(pantry: "500g Beef", ingredient: "ground beef", pantryTokens: ["beef"], ingredientTokens: ["beef"], matches: true),
        // The known false positive, asserted deliberately (ADR-0002).
        .init(pantry: "chicken breast", ingredient: "chicken stock",
              pantryTokens: ["chicken", "breast"], ingredientTokens: ["chicken", "stock"], matches: true),
        .init(pantry: "heavy cream", ingredient: "sour cream",
              pantryTokens: ["heavy", "cream"], ingredientTokens: ["sour", "cream"], matches: true),
        .init(pantry: "olive oil", ingredient: "vegetable oil",
              pantryTokens: ["olive", "oil"], ingredientTokens: ["vegetable", "oil"], matches: true),
        .init(pantry: "chicken", ingredient: "chickpeas", pantryTokens: ["chicken"], ingredientTokens: ["chickpeas"], matches: true),
        .init(pantry: "chicken", ingredient: "chicken thighs",
              pantryTokens: ["chicken"], ingredientTokens: ["chicken", "thighs"], matches: true),
        .init(pantry: "tomato", ingredient: "potato", pantryTokens: ["tomato"], ingredientTokens: ["potato"], matches: false),
        .init(pantry: "basil", ingredient: "basmati rice",
              pantryTokens: ["basil"], ingredientTokens: ["basmati", "rice"], matches: false),
        .init(pantry: "beef", ingredient: "chicken broth",
              pantryTokens: ["beef"], ingredientTokens: ["chicken", "broth"], matches: false),
        .init(pantry: "", ingredient: "tomato", pantryTokens: [], ingredientTokens: ["tomato"], matches: false),
        .init(pantry: "   ", ingredient: "tomato", pantryTokens: [], ingredientTokens: ["tomato"], matches: false),
        .init(pantry: ",.-/()", ingredient: "tomato", pantryTokens: [], ingredientTokens: ["tomato"], matches: false),
        .init(pantry: "2 1/2", ingredient: "tomato", pantryTokens: [], ingredientTokens: ["tomato"], matches: false),
        .init(pantry: "freshly chopped", ingredient: "fresh chopped tomato",
              pantryTokens: [], ingredientTokens: ["tomato"], matches: false),
        .init(pantry: "to taste", ingredient: "salt", pantryTokens: [], ingredientTokens: ["salt"], matches: false),
        .init(pantry: "tomato", ingredient: "to taste", pantryTokens: ["tomato"], ingredientTokens: [], matches: false),
        .init(pantry: "Salt & Pepper", ingredient: "black pepper",
              pantryTokens: ["salt", "pepper"], ingredientTokens: ["black", "pepper"], matches: true),
    ]

    @Test("Normalized token sets match the fixture table", arguments: fixtures)
    func normalization(fixture: TermPairFixture) {
        #expect(IngredientMatcher.normalize(fixture.pantry) == Set(fixture.pantryTokens))
        #expect(IngredientMatcher.normalize(fixture.ingredient) == Set(fixture.ingredientTokens))
    }

    @Test("Verdicts match the fixture table", arguments: fixtures)
    func verdict(fixture: TermPairFixture) {
        let matched = IngredientMatcher.termsMatch(
            pantry: IngredientMatcher.normalize(fixture.pantry),
            ingredient: IngredientMatcher.normalize(fixture.ingredient)
        )
        #expect(matched == fixture.matches)
    }
}

// MARK: - 6.3 Coverage and ranking

@Suite("Ingredient matcher — coverage and ranking")
struct CoverageAndRankingTests {

    // Scenario A — user story 7.
    static let scenarioAPantry = ["chicken", "onion", "garlic", "carrot", "celery", "salt", "pepper", "bay leaves", "noodles"]

    static let chickenNoodleSoup = MatchableRecipe(
        id: "1",
        name: "Chicken Noodle Soup",
        ingredientNames: ["chicken", "onion", "carrot", "celery", "garlic", "salt", "pepper", "bay leaves",
                          "noodles", "thyme", "parsley", "butter"]
    )
    static let garlicBread = MatchableRecipe(
        id: "2",
        name: "Garlic Bread",
        ingredientNames: ["garlic", "butter", "bread", "parsley"]
    )

    @Test("Scenario A: coverage ranks a large near-complete recipe above a small sparse one")
    func scenarioA() throws {
        let matches = try IngredientMatcher.match(
            pantryItems: Self.scenarioAPantry,
            recipes: [Self.garlicBread, Self.chickenNoodleSoup]
        )

        #expect(matches.map(\.recipeName) == ["Chicken Noodle Soup", "Garlic Bread"])

        let soup = try #require(matches.first)
        #expect(soup.matchedCount == 9)
        #expect(soup.totalCount == 12)
        #expect(soup.missingIngredients == ["thyme", "parsley", "butter"])

        // The multi-token pantry item carries the match on its second token.
        #expect(IngredientMatcher.normalize("bay leaves") == ["bay", "leaves"])
        #expect(IngredientMatcher.termsMatch(pantry: ["bay", "leaves"], ingredient: ["bay"]))

        let bread = try #require(matches.last)
        #expect(bread.matchedCount == 1)
        #expect(bread.totalCount == 4)
        #expect(bread.missingIngredients == ["butter", "bread", "parsley"])
    }

    // Scenario B — full coverage first, then the tie-breaks.
    @Test("Scenario B: full coverage ranks first, then name breaks the tie")
    func scenarioB() throws {
        let recipes = [
            MatchableRecipe(id: "w", name: "Waffles", ingredientNames: ["flour", "eggs", "milk", "butter", "sugar", "baking soda", "salt", "cinnamon"]),
            MatchableRecipe(id: "p", name: "Pancakes", ingredientNames: ["flour", "sugar", "eggs", "milk", "butter", "baking powder", "salt", "oil"]),
            MatchableRecipe(id: "c", name: "Crepes", ingredientNames: ["eggs", "flour", "milk", "butter"]),
            MatchableRecipe(id: "k", name: "Pound Cake", ingredientNames: ["butter", "sugar", "eggs", "flour", "vanilla", "salt"]),
            MatchableRecipe(id: "b", name: "Butter Cookies", ingredientNames: ["butter", "sugar", "flour", "egg"]),
        ]

        let matches = try IngredientMatcher.match(
            pantryItems: ["eggs", "butter", "flour", "sugar", "milk"],
            recipes: recipes
        )

        #expect(matches.map(\.recipeName) == ["Butter Cookies", "Crepes", "Pound Cake", "Pancakes", "Waffles"])
        #expect(matches.map(\.matchedCount) == [4, 4, 4, 5, 5])
        #expect(matches.map(\.totalCount) == [4, 4, 6, 8, 8])
        #expect(matches[2].missingIngredients == ["vanilla", "salt"])
        #expect(matches[3].missingIngredients == ["baking powder", "salt", "oil"])
        #expect(matches[4].missingIngredients == ["baking soda", "salt", "cinnamon"])
    }

    // Scenario C — equal coverage, unequal denominator.
    @Test("Scenario C: equal coverage resolves on missing ingredient count")
    func scenarioC() throws {
        let recipes = [
            MatchableRecipe(id: "f", name: "Fried Rice", ingredientNames: ["rice", "onion", "egg", "soy sauce", "oil", "peas"]),
            MatchableRecipe(id: "o", name: "Onion Soup", ingredientNames: ["onion", "broth", "bread", "cheese", "butter", "thyme"]),
            MatchableRecipe(id: "r", name: "Rice Pilaf", ingredientNames: ["rice", "onion", "broth", "butter"]),
        ]

        let matches = try IngredientMatcher.match(pantryItems: ["rice", "onion", "egg"], recipes: recipes)

        #expect(matches.map(\.recipeName) == ["Rice Pilaf", "Fried Rice", "Onion Soup"])
        #expect(matches.map { [$0.matchedCount, $0.totalCount] } == [[2, 4], [3, 6], [1, 6]])
    }

    @Test("Recipe name tie-break uses UTF-8 byte order, not Swift's string ordering")
    func utf8NameTieBreak() throws {
        // Decomposed "éclair" starts with the byte 0x65 ("e"), so it precedes
        // "zabaglione" (0x7A) in UTF-8 byte order. Swift's `<` normalizes first and
        // compares "é" (U+00E9, 233) against "z" (122), putting it second.
        let decomposed = "e\u{0301}clair"
        let recipes = [
            MatchableRecipe(id: "1", name: "zabaglione", ingredientNames: ["egg"]),
            MatchableRecipe(id: "2", name: decomposed, ingredientNames: ["egg"]),
        ]

        let matches = try IngredientMatcher.match(pantryItems: ["egg"], recipes: recipes)

        #expect(matches.map(\.recipeName) == [decomposed, "zabaglione"])
        #expect(!(decomposed < "zabaglione"), "Swift's default ordering disagrees, which is the point")
    }

    @Test("Names differing only in accent composition order by their bytes")
    func accentCompositionTieBreak() throws {
        // Swift considers these two names equal, so any equality guard on the name
        // falls through to the id tie-break and orders the NFC spelling first. Go
        // compares bytes: 0x65 ("e") precedes 0xC3 ("é"), so the NFD spelling wins.
        let precomposed = "\u{e9}clair"
        let decomposed = "e\u{0301}clair"
        let recipes = [
            MatchableRecipe(id: "a", name: precomposed, ingredientNames: ["egg"]),
            MatchableRecipe(id: "b", name: decomposed, ingredientNames: ["egg"]),
        ]

        let matches = try IngredientMatcher.match(pantryItems: ["egg"], recipes: recipes)

        #expect(matches.map(\.recipeID) == ["b", "a"])
        #expect(precomposed == decomposed, "Swift sees one name, which is the trap")
    }

    @Test("Recipe id is the final tie-break, also by UTF-8 byte order")
    func idTieBreak() throws {
        let recipes = [
            MatchableRecipe(id: "b", name: "Omelette", ingredientNames: ["egg"]),
            MatchableRecipe(id: "a", name: "Omelette", ingredientNames: ["egg"]),
        ]

        let matches = try IngredientMatcher.match(pantryItems: ["egg"], recipes: recipes)

        #expect(matches.map(\.recipeID) == ["a", "b"])
    }

    // Scenario D — degenerate inputs.
    @Test("Scenario D: a pantry of nothing but blanks is malformed", arguments: [[String](), [""], ["", "   "]])
    func blankPantryThrows(items: [String]) {
        #expect(throws: MatchError.blankPantry) {
            try IngredientMatcher.match(pantryItems: items, recipes: [Self.garlicBread])
        }
    }

    @Test("Scenario D: pantry items that normalize to empty yield no matches")
    func pantryNormalizingToEmpty() throws {
        let matches = try IngredientMatcher.match(
            pantryItems: ["to taste", "freshly chopped", ""],
            recipes: [Self.garlicBread]
        )
        #expect(matches.isEmpty)
    }

    @Test("Scenario D: duplicate pantry items contribute one matched ingredient term")
    func duplicatePantryItems() throws {
        let recipe = MatchableRecipe(id: "1", name: "Soup", ingredientNames: ["onion", "broth"])

        let matches = try IngredientMatcher.match(
            pantryItems: ["Onion", "onion", "", " onions "],
            recipes: [recipe]
        )

        let match = try #require(matches.first)
        #expect(match.matchedCount == 1)
        #expect(match.totalCount == 2)
    }

    @Test("A recipe whose ingredients all normalize to empty is never returned")
    func recipeWithNoTerms() throws {
        let recipe = MatchableRecipe(id: "1", name: "Nothing", ingredientNames: ["to taste", "freshly chopped"])

        let matches = try IngredientMatcher.match(pantryItems: ["onion"], recipes: [recipe])

        #expect(matches.isEmpty)
    }

    @Test("A recipe with zero matched ingredient terms is not returned")
    func zeroCoverageDropped() throws {
        let recipe = MatchableRecipe(id: "1", name: "Kale Salad", ingredientNames: ["kale", "lemon"])

        let matches = try IngredientMatcher.match(pantryItems: ["cake"], recipes: [recipe])

        #expect(matches.isEmpty)
    }

    @Test("Ingredients on one recipe that normalize alike count once")
    func duplicateIngredientTerms() throws {
        // Deduplication is by token set, so it collapses `2 large onions` and
        // `3 chopped onions` — but not `1 small onion`, which normalizes to
        // `{onion}` rather than `{onions}` and is a second Ingredient Term.
        let recipe = MatchableRecipe(
            id: "1",
            name: "Soup",
            ingredientNames: ["2 large onions", "3 chopped onions", "broth"]
        )

        let matches = try IngredientMatcher.match(pantryItems: ["onion"], recipes: [recipe])

        let match = try #require(matches.first)
        #expect(match.totalCount == 2)
        #expect(match.matchedCount == 1)
        #expect(match.missingIngredients == ["broth"])
    }

    @Test("Staples are not excluded from coverage")
    func staplesCount() throws {
        let recipe = MatchableRecipe(id: "1", name: "Boiled Egg", ingredientNames: ["egg", "salt"])

        let matches = try IngredientMatcher.match(pantryItems: ["eggs"], recipes: [recipe])

        let match = try #require(matches.first)
        #expect(match.totalCount == 2)
        #expect(match.missingIngredients == ["salt"])
    }
}
