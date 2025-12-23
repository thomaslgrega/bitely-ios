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
    @Query var savedRecipes: [Recipe]
    var recipeId: String
    let allowEdit: Bool
    @State var vm = RecipesTabViewVM()
    @State var recipe: Recipe?
    @State var showShoppingListSheet = false

    var isSaved: Bool {
        savedRecipes.contains(where: { $0.id == recipeId })
    }

    var savedRecipe: Recipe? {
        savedRecipes.first(where: { $0.id == recipeId })
    }

    var body: some View {
        if let recipe {
            ScrollView {
                VStack(alignment: .leading) {
                    ZStack(alignment: .topTrailing) {
                        if let imageURL = recipe.strMealThumb {
                            KFImage(URL(string: imageURL))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        }

                        ZStack {
                            Circle()
                                .frame(width: 50, height: 50)
                                .padding()
                            Button {
                                isSaved ? deleteRecipe() : bookmarkRecipe()
                            } label: {
                                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                    .bold()
                                    .foregroundStyle(Color.primaryMain)
                                    .font(.title3)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Ingredients")
                                .font(.largeTitle)
                            Spacer()
                            Button {
                                showShoppingListSheet = true
                            } label: {
                                Image(systemName: "basket")
                                    .font(.title)
                                    .foregroundStyle(Color.primaryMain)
                            }

                        }

                        ForEach(recipe.ingredients) { ingredient in
                            HStack {
                                Text(ingredient.measurement)
                                    .bold()

                                Text(ingredient.name)
                            }
                            .font(.title3)
                        }

                        Text("Instructions")
                            .font(.largeTitle)
                        Text(recipe.strInstructions ?? "")
                            .font(.title3)
                    }
                    .padding()
                }
            }
            .navigationTitle(recipe.strMeal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if allowEdit {
                    NavigationLink("Edit") {
                        EditRecipeView(recipe: recipe)
                    }
                }
            }
            .sheet(isPresented: $showShoppingListSheet) {
                RecipeShoppingListView(items: recipe.ingredients)
            }
        } else {
            ProgressView()
                .task {
                    recipe = await vm.fetchRecipeById(id: recipeId)
                }
        }
    }

    func bookmarkRecipe() {
        guard let recipe else { return }
        modelContext.insert(recipe)
    }

    func deleteRecipe() {
        guard let recipeToDelete = savedRecipe else { return }
        modelContext.delete(recipeToDelete)
    }
}

#Preview {
    RecipeInfoView(recipeId: "12345", allowEdit: true)
}
