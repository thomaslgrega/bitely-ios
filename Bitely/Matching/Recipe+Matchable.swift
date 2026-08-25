//
//  The bridge from the local store to the matcher: a stored Recipe reduced to
//  the identity, name and Ingredient names matching needs.
//
//  The matcher deliberately knows nothing about SwiftData, so the reduction
//  happens here rather than there.
//

import Foundation

extension MatchableRecipe {
    /// A Recipe on this device — Private or Saved; the local store holds both —
    /// as the matcher sees it.
    ///
    /// The `measurement` of each Ingredient is dropped: a Pantry Item asserts
    /// only that the user has some of a food, so quantity has nothing to say.
    init(_ recipe: Recipe) {
        self.init(
            id: recipe.id.uuidString,
            name: recipe.name,
            ingredientNames: recipe.ingredients.map(\.name)
        )
    }
}

extension Recipe {
    /// The ids a corpus Match may carry for this Recipe: the corpus id a Saved
    /// Recipe kept, and the Recipe's own id. Both, because that is the pair
    /// `RecipeListCardView` already recognizes a Saved Recipe by.
    var matchIdentities: [String] {
        [remoteId, id.uuidString].compactMap { $0 }
    }
}
