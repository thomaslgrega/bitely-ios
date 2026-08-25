//
//  The bridge from the wire to the matcher: a Match the corpus scored, read as
//  the same value the local pass produces.
//
//  Both sides ran the algorithm in `docs/ingredient-matching-algorithm.md` in
//  the API repo, so the two are directly comparable and the merged list can be
//  ranked as one.
//

import Foundation

extension RecipeMatch {
    /// A corpus Match as the matcher sees it.
    ///
    /// The identity is the corpus Recipe id, which is what deduplicates a Saved
    /// Recipe against its corpus original.
    init(_ dto: RecipeMatchDTO) {
        self.init(
            recipeID: dto.id,
            recipeName: dto.name,
            matchedCount: dto.matchedIngredients.count,
            totalCount: dto.matchedIngredients.count + dto.missingIngredients.count,
            missingIngredients: dto.missingIngredients
        )
    }
}
