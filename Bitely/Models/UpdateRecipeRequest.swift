import Foundation

/// What `PUT /recipes/{id}` writes: the whole Recipe, and no image field at all —
/// `bitelyapi` ADR-0006.
struct UpdateRecipeRequest: Encodable {
    let name: String
    let category: FoodCategory
    let instructions: String?
    let ingredients: [UpdateIngredientRequest]
    let calories: Int?
    let totalCookTime: Int?

    enum CodingKeys: String, CodingKey {
        case name, category, instructions, ingredients, calories
        case totalCookTime = "total_cook_time"
    }
}

/// The write replaces a Recipe's Ingredients wholesale and stores the ids it is given, so
/// the local id goes up for want of the server's — a Recipe kept from the corpus mints its
/// own. Nothing reads an Ingredient by id across the boundary, so the two never have to agree.
struct UpdateIngredientRequest: Encodable {
    let id: String
    let name: String
    let measurement: String
}

extension UpdateRecipeRequest {
    init(_ recipe: Recipe) {
        self.init(
            name: recipe.name,
            category: recipe.category,
            instructions: recipe.instructions,
            ingredients: recipe.ingredients.map {
                UpdateIngredientRequest(
                    id: $0.id.uuidString,
                    name: $0.name,
                    measurement: $0.measurement
                )
            },
            calories: recipe.calories,
            totalCookTime: recipe.totalCookTime
        )
    }
}
