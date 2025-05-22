//
//  RecipesTabViewVM.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/22/25.
//

import Foundation

enum FoodCategories: String, CaseIterable {
    case Beef, Chicken, Dessert, Lamb, Miscellaneous, Pasta, Pork, Seafood, Side, Starter, Vegan, Vegetarian, Breakfast, Goat
}

enum RecipesTabGroup {
    case all
    case favorites
    case mine
}

class RecipesTabViewVM {
    func getRecipes(category: FoodCategories, recipesTabGroup: RecipesTabGroup) -> [Recipe] {
        switch recipesTabGroup {
        case .all:
            // call external Recipes API
            return [Recipe(id: "12345", name: "Curry Rice", category: "Miscellaneous", instructions: "Boil Water")]
        case .favorites:
            // get Recipes favorited by User
            return [Recipe(id: "12345", name: "Curry Rice", category: "Miscellaneous", instructions: "Boil Water")]
        case .mine:
            // get Recipes created by the User
            return [Recipe(id: "12345", name: "Curry Rice", category: "Miscellaneous", instructions: "Boil Water")]
        }
    }
}
