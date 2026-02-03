//
//  RecipeDTO.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 1/30/26.
//

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

struct RecipeDetailDTO: Decodable, Identifiable {
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

struct IngredientDTO: Decodable, Identifiable {
    let id: String
    let name: String
    let measurement: String
}
