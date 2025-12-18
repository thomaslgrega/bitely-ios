//
//  SavedRecipesTabView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 11/28/25.
//

import SwiftData
import SwiftUI

enum RecipesDestinations: Hashable {
    case showRecipe(Recipe)
    case addRecipe(Recipe)
}

struct SavedRecipesTabView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\Recipe.strMeal)]) var recipes: [Recipe]

    var savedRecipesId: Set<String> {
        Set(recipes.map { $0.id })
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(recipes) { recipe in
                    NavigationLink(recipe.strMeal, value: RecipesDestinations.showRecipe(recipe))
                }
                .onDelete(perform: deleteSavedRecipe)
            }
            .toolbar {
                NavigationLink("Add Recipe", value: RecipesDestinations.addRecipe(Recipe(id: UUID().uuidString, strMeal: "", strMealThumb: "")))
            }
            .navigationDestination(for: RecipesDestinations.self) { destination in
                switch destination {
                case .addRecipe(let recipe):
                    EditRecipeView(recipe: recipe)
                case .showRecipe(let recipe):
                    RecipeInfoView(savedRecipeIds: savedRecipesId, recipeId: recipe.id, recipe: recipe)
                }
            }
        }
    }

    func deleteSavedRecipe(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(recipes[index])
        }
    }
}

#Preview {
    SavedRecipesTabView()
}
