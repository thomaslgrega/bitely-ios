//
//  CreateRecipeRequest.swift
//  Bitely
//
//  Created by Thomas Grega on 2/4/26.
//

import Foundation

struct CreateRecipeRequest: Encodable {
    let name: String
    let category: FoodCategory
    let instructions: String?
    let thumbnailUrl: String?
    let ingredients: [CreateIngredientRequest]
    let calories: Int?
    let totalCookTime: Int?
}

struct CreateIngredientRequest: Encodable {
    let name: String
    let measurement: String
}
