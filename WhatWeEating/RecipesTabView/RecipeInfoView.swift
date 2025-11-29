//
//  RecipeInfoView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/27/25.
//

import Kingfisher
import SwiftData
import SwiftUI

struct RecipeInfoView: View {
    @Environment(\.modelContext) var modelContext
    var recipeId: String
    @Binding var vm: RecipesTabViewVM
    @State private var recipe: Recipe?

    var body: some View {
        if let recipe {
            ScrollView {
                VStack(alignment: .leading) {
                    ZStack(alignment: .topTrailing) {
                        KFImage(URL(string: recipe.strMealThumb))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)

                        ZStack {
                            Circle()
                                .frame(width: 50, height: 50)
                                .padding()
                            Button {
                                saveRecipe()
                            } label: {
                                Image(systemName: "bookmark")
                                    .bold()
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }

                        }
                    }

                    Text("Ingredients")
                        .font(.largeTitle)
                    ForEach(Array(recipe.ingredients.keys), id: \.self) { ingredient in
                        HStack {
                            Text("\(recipe.ingredients[ingredient] ?? "")")
                                .bold()
                                .font(.title3)

                            Text(ingredient)
                                .font(.title3)
                        }
                    }

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

    func saveRecipe() {
        guard let recipe else { return }
        modelContext.insert(recipe)
    }
}

#Preview {
    RecipeInfoView(recipeId: "12345", vm: .constant(RecipesTabViewVM()))
}
