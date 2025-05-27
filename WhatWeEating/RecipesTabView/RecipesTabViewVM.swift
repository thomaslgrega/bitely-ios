//
//  RecipesTabViewVM.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/22/25.
//

import SwiftUI

enum FoodCategories: String, CaseIterable {
    case Beef, Chicken, Dessert, Lamb, Miscellaneous, Pasta, Pork, Seafood, Side, Starter, Vegan, Vegetarian, Breakfast, Goat
}

enum RecipesTabGroup {
    case all
    case favorites
    case mine
}

@Observable
class RecipesTabViewVM {
    private let baseURL = "https://www.themealdb.com/api/json/v1/1/"

    var recipes = [Recipe]()

    func fetchRecipesByCategory(category: FoodCategories) async {
        guard let url = URL(string: baseURL + "filter.php?c=\(category.rawValue)") else {
            print("Bad URL")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode(Response.self, from: data)
            recipes = decodedData.meals
        } catch {
            print(error)
        }
    }
}
