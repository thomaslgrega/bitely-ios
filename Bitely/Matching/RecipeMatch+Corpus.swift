//
//  The bridge from the wire to the matcher: a Match the corpus scored, read as
//  the same value the local pass produces. `PantryMatch` explains why the two
//  are comparable at all.
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
