import Foundation
import SwiftData

enum FoodCategory: String, CaseIterable, Hashable, Codable {
    case beef = "Beef"
    case chicken = "Chicken"
    case dessert = "Dessert"
    case other = "Other"
    case pasta = "Pasta"
    case pork = "Pork"
    case seafood = "Seafood"
    case side = "Side"
    case vegetarian = "Vegetarian"
    case breakfast = "Breakfast"
}

extension FoodCategory {
    /// The category text the corpus carries, which is not constrained to these ten cases.
    /// A build that has not been taught a category files it under `.other` rather than
    /// rejecting it, so one such Recipe shows up under the general heading instead of
    /// failing the whole response it arrived in.
    init(apiValue: String) {
        self = FoodCategory(rawValue: apiValue) ?? .other
    }

    /// Encoding stays the synthesized raw-value one, so sharing a Recipe still round-trips.
    init(from decoder: any Decoder) throws {
        self.init(apiValue: try decoder.singleValueContainer().decode(String.self))
    }
}

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var remoteId: String?
    var name: String
    var categoryRaw: String
    var instructions: String?
    var thumbnailURL: String?
    var imageData: Data?
    var calories: Int?
    var totalCookTime: Int?

    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]

    var category: FoodCategory {
        get {
            FoodCategory(apiValue: categoryRaw)
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        remoteId: String? = nil,
        name: String,
        category: FoodCategory,
        instructions: String? = nil,
        thumbnailURL: String? = nil,
        ingredients: [Ingredient] = [],
        calories: Int? = nil,
        totalCookTime: Int? = nil
    ) {
        self.id = id
        self.remoteId = remoteId
        self.name = name
        self.categoryRaw = category.rawValue
        self.instructions = instructions
        self.thumbnailURL = thumbnailURL
        self.ingredients = ingredients
        self.calories = calories
        self.totalCookTime = totalCookTime
    }
}

extension Recipe {
    /// The device's copy of a corpus Recipe. Every save builds it here, so one kept from a
    /// tile and one kept from the detail screen are the same local Recipe.
    convenience init(_ dto: RecipeDetailDTO) {
        self.init(
            remoteId: dto.id,
            name: dto.name,
            category: dto.category,
            instructions: dto.instructions,
            thumbnailURL: dto.thumbnailUrl,
            ingredients: dto.ingredients.map { Ingredient(name: $0.name, measurement: $0.measurement) },
            calories: dto.calories,
            totalCookTime: dto.totalCookTime
        )
    }
}


