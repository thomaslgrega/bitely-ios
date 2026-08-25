//
//  A Swift port of the ingredient matching algorithm, so Private Recipes held on
//  the device can be matched without a network round trip.
//
//  The specification is `docs/ingredient-matching-algorithm.md` in the API repo
//  (thomaslgrega/bitelyapi). **That document is the source of truth, not this
//  file and not the Go implementation.** Per ADR-0001 the algorithm exists in
//  two languages and the two must agree exactly; the fixture table in section 6
//  of that document is the mechanism that keeps them in step, and it is
//  transcribed into `BitelyTests/IngredientMatcherTests.swift`.
//
//  Deliberately free of SwiftData, networking and SwiftUI: it takes plain
//  strings in and hands plain values back, so it can be tested against fixtures
//  alone.
//

import Foundation

/// A Recipe reduced to what matching needs: an identity, a name for the
/// tie-break, and its Ingredient names in the Recipe's own order.
struct MatchableRecipe: Hashable, Sendable {
    let id: String
    let name: String
    let ingredientNames: [String]
}

/// One Recipe the Pantry covers at least one Ingredient Term of.
///
/// Coverage is kept as the integer pair `matchedCount / totalCount` rather than a
/// quotient, both so the interface can say "you have 4 of 6 ingredients" and so
/// ranking can compare by cross-multiplication instead of by dividing.
struct RecipeMatch: Hashable, Sendable {
    let recipeID: String
    let recipeName: String
    let matchedCount: Int
    let totalCount: Int
    /// The raw Ingredient names the Pantry does not cover, in the Recipe's own
    /// Ingredient order.
    let missingIngredients: [String]
}

enum MatchError: Error, Equatable {
    /// Every submitted string was blank, or the list itself was empty. A blank
    /// names no food, so such a request carries no Pantry Item at all and is
    /// malformed rather than a pantry that matches nothing (ADR-0003).
    case blankPantry
}

enum IngredientMatcher {

    /// The threshold as integers, which is how it is actually applied: `0.3` is
    /// not representable in binary floating point and `egg`/`eggplant` lands
    /// exactly on it.
    static let thresholdNumerator = 3
    static let thresholdDenominator = 10

    /// A token pair at or above this scores a match. The match is binary: there
    /// is no fractional credit, because Coverage must remain an integer ratio.
    static let matchThreshold = Double(thresholdNumerator) / Double(thresholdDenominator)

    // MARK: - Stopwords

    /// Transcribed from section 2.1 of `docs/ingredient-matching-algorithm.md`
    /// in the API repo, which is where the list lives and what it should contain.
    /// This is the Swift mirror of `MeasurementStopwords` in the Go package;
    /// neither transcription is upstream of the other. Multi-word aliases
    /// (`fl oz`, `to taste`) appear as their component tokens, because
    /// normalization has already tokenized by the time stopwords are applied.
    ///
    /// When this list changes, it changes in section 2.1 first, and both
    /// transcriptions change with it in the same review cycle.
    static let measurementStopwords: Set<String> = [
        // Volume
        "tsp", "t", "teaspoon", "teaspoons",
        "tbsp", "tablespoon", "tablespoons", "tbs",
        "fl", "floz", "fluid", "ounce", "ounces",
        "cup", "cups", "c",
        "pint", "pints", "pt",
        "quart", "quarts", "qt",
        "gallon", "gallons", "gal",
        "ml", "milliliter", "milliliters", "millilitre", "millilitres",
        "l", "liter", "liters", "litre", "litres",

        // Mass
        "g", "gram", "grams",
        "kg", "kilogram", "kilograms",
        "oz",
        "lb", "lbs", "pound", "pounds",

        // Count
        "piece", "pieces", "whole",
        "clove", "cloves",
        "can", "cans", "tin", "tins",
        "slice", "slices",

        // Special
        "pinch", "pinches",
        "dash", "dashes",
        "handful", "handfuls",
        "to", "taste",
    ]

    /// Preparation and size words that describe how a food arrives rather than
    /// what it is, plus the function words that appear inside ingredient lines.
    ///
    /// Colour and variety words are deliberately absent: matching is per token,
    /// so they cost nothing, and dropping them would erase `sweet potato` and
    /// `green onion`.
    static let descriptorStopwords: Set<String> = [
        // Preparation
        "chopped", "diced", "minced", "sliced", "shredded", "grated", "crushed", "ground",
        "mashed", "cubed", "julienned", "halved", "quartered", "trimmed", "peeled", "seeded",
        "pitted", "stemmed", "rinsed", "drained", "softened", "melted", "beaten", "packed",
        "sifted", "toasted", "roasted", "cooked", "uncooked", "raw", "boneless", "skinless",

        // Condition and quality
        "fresh", "freshly", "frozen", "dried", "ripe", "unsalted", "unsweetened", "plain",
        "low", "reduced", "room", "temperature", "warm", "cold", "hot", "boiling",

        // Size and amount
        "large", "small", "medium", "extra", "thin", "thick", "finely", "coarsely", "thinly",
        "thickly", "lightly", "heaping", "scant",

        // Line noise
        "optional", "divided", "plus", "more", "needed", "garnish", "and", "or", "of", "the", "a",
        "an", "for", "with", "into", "in", "on", "about", "approximately",
    ]

    // MARK: - Normalization

    /// Turns one raw string — a Pantry Item as typed, or an Ingredient name as
    /// written — into an Ingredient Term: a set of tokens.
    ///
    /// The steps run in the order section 1 gives, and the order is part of the
    /// specification. Splitting before stripping is what keeps `fl.oz` from
    /// fusing into `floz` and `salt/pepper` into `saltpepper`.
    ///
    /// The empty set is a legal result.
    static func normalize(_ raw: String) -> Set<String> {
        var tokens: Set<String> = []
        var current = ""

        func flush() {
            defer { current = "" }
            // Strip digits, then drop the token if nothing is left or it is a stopword.
            let stripped = current.filter { !isDecimalDigit($0) }
            guard !stripped.isEmpty,
                  !measurementStopwords.contains(stripped),
                  !descriptorStopwords.contains(stripped) else { return }
            tokens.insert(stripped)
        }

        for character in raw.lowercased() {
            if character.isLetter || isDecimalDigit(character) {
                current.append(character)
            } else {
                flush()
            }
        }
        flush()

        return tokens
    }

    /// True for Unicode category `Nd` only. `½` is `No` and so is a boundary
    /// character rather than a digit.
    private static func isDecimalDigit(_ character: Character) -> Bool {
        character.unicodeScalars.count == 1
            && character.unicodeScalars.first?.properties.numericType == .decimal
    }

    // MARK: - Similarity

    /// The trigram set `pg_trgm` would extract from a single token: two leading
    /// pad spaces, one trailing, then every contiguous three-character window.
    /// A set, not a multiset — `banana` contributes one `ana`.
    static func trigrams(of token: String) -> Set<String> {
        let padded = Array("  " + token + " ")
        guard padded.count >= 3 else { return [] }

        var result: Set<String> = []
        for offset in 0...(padded.count - 3) {
            result.insert(String(padded[offset..<(offset + 3)]))
        }
        return result
    }

    /// Whether two tokens score at or above `matchThreshold`, by integer
    /// cross-multiplication rather than division.
    static func tokensMatch(_ a: String, _ b: String) -> Bool {
        let left = trigrams(of: a)
        let right = trigrams(of: b)
        let union = left.union(right).count
        guard union > 0 else { return false }

        return left.intersection(right).count * thresholdDenominator >= union * thresholdNumerator
    }

    // MARK: - Comparison is per token

    /// A Pantry Item matches an Ingredient Term when any token of the one scores
    /// at or above the threshold against any token of the other. Never compare
    /// whole strings: see section 4.
    static func termsMatch(pantry: Set<String>, ingredient: Set<String>) -> Bool {
        pantry.contains { pantryToken in
            ingredient.contains { tokensMatch(pantryToken, $0) }
        }
    }

    // MARK: - Coverage and ranking

    /// Matches `recipes` against `pantryItems` and returns them ranked.
    ///
    /// Recipes with no Ingredient Terms, and Recipes the Pantry covers none of,
    /// are not returned: a Match with Coverage `0` offers the user a Recipe they
    /// hold no Ingredient for.
    ///
    /// - Throws: `MatchError.blankPantry` when every submitted string is blank or
    ///   the list is empty.
    static func match(pantryItems: [String], recipes: [MatchableRecipe]) throws -> [RecipeMatch] {
        let submitted = pantryItems.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !submitted.isEmpty else { throw MatchError.blankPantry }

        // Normalize, discard the ones that normalize to empty, deduplicate by token set.
        let pantryTerms = Set(submitted.map(normalize)).filter { !$0.isEmpty }

        let matches = recipes.compactMap { recipe -> RecipeMatch? in
            let terms = ingredientTerms(of: recipe)
            guard !terms.isEmpty else { return nil }

            let missing = terms.filter { term in
                !pantryTerms.contains { termsMatch(pantry: $0, ingredient: term.tokens) }
            }
            let matchedCount = terms.count - missing.count
            guard matchedCount > 0 else { return nil }

            return RecipeMatch(
                recipeID: recipe.id,
                recipeName: recipe.name,
                matchedCount: matchedCount,
                totalCount: terms.count,
                missingIngredients: missing.map(\.rawName)
            )
        }

        return matches.sorted(by: ranksBefore)
    }

    /// One Ingredient Term, carrying the raw name it came from so a Missing
    /// Ingredient can be reported as the Author wrote it.
    private struct Term {
        let rawName: String
        let tokens: Set<String>
    }

    /// A Recipe's Ingredient Terms, in the Recipe's own Ingredient order, with
    /// the empty ones discarded and duplicates by token set collapsed. The
    /// `measurement` field is never read: quantity is ignored entirely.
    private static func ingredientTerms(of recipe: MatchableRecipe) -> [Term] {
        var seen: Set<Set<String>> = []
        var terms: [Term] = []

        for name in recipe.ingredientNames {
            let tokens = normalize(name)
            guard !tokens.isEmpty, seen.insert(tokens).inserted else { continue }
            terms.append(Term(rawName: name, tokens: tokens))
        }

        return terms
    }

    /// Coverage descending, then Missing Ingredient count ascending, then name,
    /// then id — the last two by UTF-8 byte order, which is what Go's `<` on
    /// `string` does. Swift's `<` on `String` compares by Unicode canonical
    /// equivalence and would order names differing only in accent composition
    /// differently from the Go implementation.
    private static func ranksBefore(_ lhs: RecipeMatch, _ rhs: RecipeMatch) -> Bool {
        // Cross-multiply rather than divide, so both implementations agree exactly.
        let lhsCoverage = lhs.matchedCount * rhs.totalCount
        let rhsCoverage = rhs.matchedCount * lhs.totalCount
        if lhsCoverage != rhsCoverage { return lhsCoverage > rhsCoverage }

        let lhsMissing = lhs.missingIngredients.count
        let rhsMissing = rhs.missingIngredients.count
        if lhsMissing != rhsMissing { return lhsMissing < rhsMissing }

        // Compare the bytes throughout. Testing the names with `!=` first would
        // reintroduce canonical equivalence: NFC and NFD spellings of one name are
        // `==` in Swift but order by bytes in Go.
        let lhsName = Array(lhs.recipeName.utf8)
        let rhsName = Array(rhs.recipeName.utf8)
        if lhsName != rhsName { return lhsName.lexicographicallyPrecedes(rhsName) }

        return Array(lhs.recipeID.utf8).lexicographicallyPrecedes(Array(rhs.recipeID.utf8))
    }
}
