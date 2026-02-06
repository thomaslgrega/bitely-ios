//
//  File.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/20/25.
//

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
            FoodCategory(rawValue: categoryRaw) ?? .other
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


