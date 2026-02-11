//
//  RecipeService.swift
//  Bitely
//
//  Created by Thomas Grega on 1/29/26.
//

import Foundation

@Observable
final class RecipeService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func getRecipeById(id: String) async throws -> RecipeDetailDTO {
        try await api.request(path: "recipes/\(id)")
    }

    func getRecipesByCategory(category: FoodCategory) async throws -> [RecipeSummaryDTO] {
        try await api.request(path: "recipes", query: [URLQueryItem(name: "category", value: category.rawValue)])
    }

    func getSharedRecipes() async throws -> [RecipeSummaryDTO] {
        try await api.request(path: "me/recipes", requiresAuth: true)
    }

    func deleteSharedRecipe(id: String) async throws {
        try await api.requestNoResponse(path: "recipes/\(id)", method: "DELETE", requiresAuth: true)
    }

    func createRecipe(recipe: CreateRecipeRequest) async throws -> RecipeDetailDTO {
        let data = try JSONEncoder().encode(recipe)
        return try await api.request(path: "recipes", method: "POST", body: data, requiresAuth: true)
    }
}
