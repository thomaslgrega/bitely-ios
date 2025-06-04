//
//  RecipeInfoView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/27/25.
//

import Kingfisher
import SwiftUI

struct RecipeInfoView: View {
    var recipeId: String

    @Binding var vm: RecipesTabViewVM
    @State private var recipe: Recipe?

    var body: some View {
        if let recipe {
            ScrollView {
                VStack {
                    KFImage(URL(string: recipe.strMealThumb))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)

                    Text("Ingredients")
                        .font(.largeTitle)

                    Text("Instructions")
                        .font(.largeTitle)
                    Text(recipe.strInstructions ?? "")
                        .font(.title3)
                }
            }
            .navigationTitle(recipe.strMeal)
            .navigationBarTitleDisplayMode(.inline)
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
