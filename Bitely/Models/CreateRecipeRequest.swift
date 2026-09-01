import Foundation

struct CreateRecipeRequest: Encodable {
    let name: String
    let category: FoodCategory
    let instructions: String?
    /// The staged upload this share claims — `bitelyapi` ADR-0006. Nothing fills it yet.
    let imageKey: String?
    let ingredients: [CreateIngredientRequest]
    let calories: Int?
    let totalCookTime: Int?

    enum CodingKeys: String, CodingKey {
        case name, category, instructions
        case imageKey = "image_key"
        case ingredients, calories
        case totalCookTime = "total_cook_time"
    }
}

struct CreateIngredientRequest: Encodable {
    let name: String
    let measurement: String
}
