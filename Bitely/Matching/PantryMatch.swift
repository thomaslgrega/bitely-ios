//
//  The two ranked lists as one: the corpus pass the API ran over Shared
//  Recipes, and the local pass over this device.
//
//  Both sides applied `docs/ingredient-matching-algorithm.md` in the API repo,
//  so their Coverage values are directly comparable and merging is a re-sort on
//  the comparison keys of section 5 — not two lists stapled together.
//

import Foundation

/// Where a Match came from, which is what tapping it has to open.
enum MatchSource: Hashable, Sendable {
    /// A Recipe in the local store, Private or Saved, keyed by its local id.
    case local
    /// A Shared Recipe in the corpus, keyed by its corpus id.
    case corpus
}

struct PantryMatch: Hashable, Sendable, Identifiable {
    let match: RecipeMatch
    let source: MatchSource

    var id: String { match.recipeID }
}

extension PantryMatch {
    /// Merges the corpus Matches into the local ones and ranks the result.
    ///
    /// A Saved Recipe matches on both sides — it is in the corpus and on the
    /// device — and is kept once, as the local copy, which carries the user's
    /// own image data.
    ///
    /// - Parameter localIdentities: the ids each Recipe answers to, keyed by the
    ///   id its local Match carries. Only the Recipes the local pass matched can
    ///   stand in for a corpus Match: deduplicating against the whole store
    ///   instead would drop a Saved Recipe the corpus matched and the local copy
    ///   did not, and the user's edits to their own copy would make the Recipe
    ///   vanish rather than appear once.
    static func merge(
        local: [RecipeMatch],
        corpus: [RecipeMatch],
        localIdentities: [String: [String]]
    ) -> [PantryMatch] {
        let alreadyShown = Set(local.flatMap { localIdentities[$0.recipeID] ?? [] })

        let localMatches = local.map { PantryMatch(match: $0, source: .local) }
        let corpusMatches = corpus
            .filter { !alreadyShown.contains($0.recipeID) }
            .map { PantryMatch(match: $0, source: .corpus) }

        return (localMatches + corpusMatches).sorted {
            IngredientMatcher.ranksBefore($0.match, $1.match)
        }
    }
}
