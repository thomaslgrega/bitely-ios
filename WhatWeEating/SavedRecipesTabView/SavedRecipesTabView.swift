//
//  SavedRecipesTabView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 11/28/25.
//

import SwiftData
import SwiftUI

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
                    NavigationLink(recipe.strMeal, value: recipe)
                }
                .onDelete(perform: deleteSavedRecipe)
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeInfoView(savedRecipeIds: savedRecipesId, recipeId: recipe.id, recipe: recipe)
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
