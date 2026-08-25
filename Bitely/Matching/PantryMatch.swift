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

/// One Match in the merged list.
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
    /// own image data. `localIdentities` names the ids the device already
    /// answers to; the corpus Matches under them are the duplicates.
    static func merge(
        local: [RecipeMatch],
        corpus: [RecipeMatch],
        localIdentities: Set<String>
    ) -> [PantryMatch] {
        let localMatches = local.map { PantryMatch(match: $0, source: .local) }
        let corpusMatches = corpus
            .filter { !localIdentities.contains($0.recipeID) }
            .map { PantryMatch(match: $0, source: .corpus) }

        return (localMatches + corpusMatches).sorted {
            IngredientMatcher.ranksBefore($0.match, $1.match)
        }
    }
}
