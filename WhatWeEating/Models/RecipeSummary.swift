//
//  BackendRecipe.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 1/29/26.
//

import Foundation

struct RecipeSummary: Identifiable, Hashable {
    let id: String
    let remoteId: String?
    let name: String
    let category: FoodCategory
    let thumbnailUrl: String?
    let imageData: Data?
    let calories: Int?
    let totalCookTime: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name, category
        case thumbnailUrl = "thumbnail_url"
        case imageData = "image_data"
        case calories
        case totalCookTime = "total_cook_time"
    }
}

//extension RecipeSummary {
//    init(recipe: Recipe) {
//        self.id = recipe.id.uuidString
//        self.name = recipe.name
//        self.category = recipe.category
//        self.thumbnailUrl = recipe.thumbnailURL
//        self.imageData = recipe.imageData
//        self.calories = recipe.calories
//        self.totalCookTime = recipe.totalCookTime
//    }
//
//    init(recipeDTO: RecipeSummaryDTO) {
//        self.id = recipeDTO.id
//        self.name = recipeDTO.name
//        self.category = recipeDTO.category
//        self.thumbnailUrl = recipeDTO.thumbnailUrl
//        self.imageData = nil
//        self.calories = recipeDTO.calories
//        self.totalCookTime = recipeDTO.totalCookTime
//    }
//}
//
//
