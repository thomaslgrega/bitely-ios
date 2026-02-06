//
//  RemoteRecipeInfoView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 2/2/26.
//

import SwiftData
import SwiftUI

struct RemoteRecipeInfoView: View {
    @Environment(RecipeService.self) private var recipeService
    @Environment(\.modelContext) private var modelContext
    @Query private var savedRecipes: [Recipe]

    let recipeId: String
    let allowEdit: Bool

    @State private var recipe: Recipe?

    var isSaved: Bool {
        savedRecipes.contains(where: { $0.remoteId == recipeId })
    }

    var savedRecipe: Recipe? {
        savedRecipes.first(where: { $0.remoteId == recipeId })
    }

    var body: some View {
        Group {
            if let recipe {
                RecipeInfoContentView(
                    recipe: recipe,
                    allowEdit: allowEdit,
                    isSaved: isSaved,
                    onToggleBookmark: { isSaved ? deleteSavedCopy() : bookmarkRemoteRecipe() })
            } else {
                ProgressView()
                    .task(id: recipeId) {
                        await load()
                    }
            }
        }
    }

    private func load() async {
        guard recipe == nil else { return }
        do {
            let dto = try await recipeService.getRecipeById(id: recipeId)
            let ingredients = dto.ingredients.map {
                Ingredient(name: $0.name, measurement: $0.measurement)
            }

            recipe = Recipe(
                remoteId: dto.id,
                name: dto.name,
                category: dto.category,
                instructions: dto.instructions,
                thumbnailURL: dto.thumbnailUrl,
                ingredients: ingredients,
                calories: dto.calories,
                totalCookTime: dto.totalCookTime
            )
        } catch {
            print("Error fetching recipe:", error)
        }
    }

    private func bookmarkRemoteRecipe() {
        guard let recipe else { return }
        guard !isSaved else { return }

        let ingredients = recipe.ingredients.map {
            Ingredient(name: $0.name, measurement: $0.measurement)
        }

        let copy = Recipe(
            remoteId: recipe.remoteId,
            name: recipe.name,
            category: recipe.category,
            instructions: recipe.instructions,
            thumbnailURL: recipe.thumbnailURL,
            ingredients: ingredients,
            calories: recipe.calories,
            totalCookTime: recipe.totalCookTime
        )
        modelContext.insert(copy)
    }

    private func deleteSavedCopy() {
        guard let toDelete = savedRecipe else { return }
        modelContext.delete(toDelete)
    }
}

#Preview {
    RemoteRecipeInfoView(recipeId: "12345", allowEdit: false)
}
