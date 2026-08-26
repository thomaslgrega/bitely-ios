import Foundation

struct RecipeSummaryDTO: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: FoodCategory
    let thumbnailUrl: String?
    let calories: Int?
    let totalCookTime: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, category, calories
        case thumbnailUrl = "thumbnail_url"
        case totalCookTime = "total_cook_time"
    }
}

extension RecipeSummaryDTO {
    /// The summary carried by a Recipe the API has just answered in full — what a grid
    /// needs of a Recipe the device holds no copy of.
    init(_ detail: RecipeDetailDTO) {
        self.init(
            id: detail.id,
            name: detail.name,
            category: detail.category,
            thumbnailUrl: detail.thumbnailUrl,
            calories: detail.calories,
            totalCookTime: detail.totalCookTime
        )
    }
}

struct RecipeDetailDTO: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let category: FoodCategory
    let instructions: String?
    let thumbnailUrl: String?
    let ingredients: [IngredientDTO]
    let calories: Int?
    let totalCookTime: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, category, instructions, ingredients, calories
        case thumbnailUrl = "thumbnail_url"
        case totalCookTime = "total_cook_time"
    }
}

struct IngredientDTO: Codable, Identifiable {
    let id: String
    let name: String
    let measurement: String
}

/// One Match as the corpus reports it.
///
/// The wire also carries a `coverage` float and the recipe-card fields; neither
/// is decoded. Coverage is re-derived from the two Ingredient lists because
/// ranking compares the counts as integers, and a Match opens through
/// `RemoteRecipeInfoView`, which fetches the Recipe in full.
struct RecipeMatchDTO: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let matchedIngredients: [String]
    let missingIngredients: [String]

    enum CodingKeys: String, CodingKey {
        case id, name
        case matchedIngredients = "matched_ingredients"
        case missingIngredients = "missing_ingredients"
    }
}
