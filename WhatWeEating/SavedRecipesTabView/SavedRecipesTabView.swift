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
    case editRecipe(Recipe)
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
                NavigationLink("Add Recipe", value: RecipesDestinations.editRecipe(Recipe(id: UUID().uuidString, strMeal: "", strMealThumb: "", calories: nil, totalCookTime: nil)))
            }
            .navigationDestination(for: RecipesDestinations.self) { destination in
                switch destination {
                case .editRecipe(let recipe):
                    EditRecipeView(recipe: recipe)
                case .showRecipe(let recipe):
                    RecipeInfoView(recipeId: recipe.id, allowEdit: true, recipe: recipe)
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
