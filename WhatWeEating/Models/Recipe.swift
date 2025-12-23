//
//  File.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/20/25.
//

import Foundation
import SwiftData

struct Response: Codable {
    var meals: [Recipe]
}

@Model
class Recipe: Codable, Identifiable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id = "idMeal"
        case strMeal, strCategory, strInstructions, strMealThumb
        case strIngredient1
        case strIngredient2
        case strIngredient3
        case strIngredient4
        case strIngredient5
        case strIngredient6
        case strIngredient7
        case strIngredient8
        case strIngredient9
        case strIngredient10
        case strIngredient11
        case strIngredient12
        case strIngredient13
        case strIngredient14
        case strIngredient15
        case strIngredient16
        case strIngredient17
        case strIngredient18
        case strIngredient19
        case strIngredient20
        case strMeasure1
        case strMeasure2
        case strMeasure3
        case strMeasure4
        case strMeasure5
        case strMeasure6
        case strMeasure7
        case strMeasure8
        case strMeasure9
        case strMeasure10
        case strMeasure11
        case strMeasure12
        case strMeasure13
        case strMeasure14
        case strMeasure15
        case strMeasure16
        case strMeasure17
        case strMeasure18
        case strMeasure19
        case strMeasure20
    }

    var id: String
    var name: String
    var category: FoodCategory?
    var instructions: String?
    var thumbnailURL: String?

    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]

    var calories: Int?
    var totalCookTime: Int?

    init(id: String, name: String, category: FoodCategory? = nil, instructions: String? = nil, thumbnailURL: String? = nil, ingredients: [Ingredient] = [], calories: Int?, totalCookTime: Int?) {
        self.id = id
        self.name = name
        self.category = category
        self.instructions = instructions
        self.thumbnailURL = thumbnailURL
        self.ingredients = ingredients
        self.calories = calories
        self.totalCookTime = totalCookTime
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .strMeal)
        category = try container.decodeIfPresent(FoodCategory.self, forKey: .strCategory)
        instructions = try container.decodeIfPresent(String.self, forKey: .strInstructions)
        thumbnailURL = try container.decodeIfPresent(String.self, forKey: .strMealThumb)

        var ingredients = [Ingredient]()
        for i in 1...20 {
            let nameKey = CodingKeys(stringValue: "strIngredient\(i)")!
            let measurementKey = CodingKeys(stringValue: "strMeasure\(i)")!

            let name = try container.decodeIfPresent(String.self, forKey: nameKey) ?? ""
            let measurement = try container.decodeIfPresent(String.self, forKey: measurementKey) ?? ""

            if name == "" { break }

            ingredients.append(Ingredient(name: name, measurement: measurement))
        }

        self.ingredients = ingredients
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .strMeal)
        try container.encode(category, forKey: .strCategory)
        try container.encode(instructions, forKey: .strInstructions)
        try container.encode(thumbnailURL, forKey: .strMealThumb)
    }
}
