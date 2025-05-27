//
//  RecipeInfoView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/27/25.
//

import SwiftUI

struct RecipeInfoView: View {
    var recipeId: String

    @Binding var vm: RecipesTabViewVM
    @State private var recipe: Recipe?

    var body: some View {
        if let recipe {
            ScrollView {
                Text("Instructions")
                    .font(.title)
                Text(recipe.strInstructions ?? "")

            }
            .navigationTitle(recipe.strMeal)
            .navigationBarTitleDisplayMode(.large)
        } else {
            ProgressView()
                .task {
                    recipe = await vm.fetchRecipeById(id: recipeId)
                }
        }
    }
}

#Preview {
    RecipeInfoView(recipeId: "12345", vm: .constant(RecipesTabViewVM()))
}
