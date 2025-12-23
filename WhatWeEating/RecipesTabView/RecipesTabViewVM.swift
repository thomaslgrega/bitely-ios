//
//  RecipesTabViewVM.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/22/25.
//

import SwiftUI

enum FoodCategory: String, CaseIterable, Hashable, Codable {
    case beef = "Beef"
    case chicken = "Chicken"
    case dessert = "Dessert"
    case lamb = "Lamb"
    case miscellaneous = "Miscellaneous"
    case pasta = "Pasta"
    case pork = "Pork"
    case seafood = "Seafood"
    case side = "Side"
    case starter = "Starter"
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case breakfast = "Breakfast"
    case goat = "Goat"
}

@Observable
class RecipesTabViewVM {
    private let baseURL = "https://www.themealdb.com/api/json/v1/1/"

    var recipes = [Recipe]()

    func fetchRecipesByCategory(category: FoodCategory) async {
        guard let url = URL(string: baseURL + "filter.php?c=\(category.rawValue)") else {
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

    func fetchRecipeById(id: String) async -> Recipe? {
        guard let url = URL(string: baseURL + "lookup.php?i=\(id)") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode(Response.self, from: data)
            return decodedData.meals.first
        } catch {
            print(error)
            return nil
        }
    }
}
