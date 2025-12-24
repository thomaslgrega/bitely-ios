//
//  RecipeInfoView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/27/25.
//

import Kingfisher
import SwiftData
import SwiftUI

enum RecipeTab {
    case ingredients
    case instructions
}

struct RecipeInfoView: View {
    @Environment(\.modelContext) var modelContext
    @Query var savedRecipes: [Recipe]
    var recipeId: String
    let allowEdit: Bool
    @State var vm = RecipesTabViewVM()
    @State var recipe: Recipe?

    @State private var selectedTab: RecipeTab = .ingredients

    var isSaved: Bool {
        savedRecipes.contains(where: { $0.id == recipeId })
    }

    var savedRecipe: Recipe? {
        savedRecipes.first(where: { $0.id == recipeId })
    }

    var body: some View {
        if let recipe {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    ZStack(alignment: .topTrailing) {
                        if let imageURL = recipe.thumbnailURL {
                            KFImage(URL(string: imageURL))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        } else {
                            Image(recipe.category?.rawValue.lowercased() ?? "miscellaneous")
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

                    Text(recipe.name)
                        .font(.title)
                        .foregroundStyle(Color.secondaryMain)

                    HStack(spacing: 40) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(Color.primaryMain)
                            Text(recipe.calories.map { "\($0) cals"} ?? "N/A")
                                .foregroundStyle(Color.secondaryMain)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(Color.primaryMain)
                            Text(recipe.totalCookTime.map { "\($0) min" } ?? "N/A")
                                .foregroundStyle(Color.secondaryMain)
                        }

                        HStack(spacing: 4) {
                            NavigationLink {
                                RecipeShoppingListView(items: recipe.ingredients)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "basket.fill")
                                        .foregroundStyle(Color.primaryMain)

                                    Text("Add to")
                                        .foregroundStyle(Color.primaryMain)
                                }
                            }

                        }
                    }

                    CustomSegmentedControl(
                        selection: $selectedTab,
                        options: [
                            (.ingredients, "Ingredients"),
                            (.instructions, "Instructions")
                        ]
                    )
                    .padding(.vertical)

                    ZStack {
                        switch selectedTab {
                        case .ingredients:
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(recipe.ingredients) { ingredient in
                                    HStack {
                                        Text(ingredient.measurement)
                                            .bold()
                                        Text(ingredient.name)
                                    }
                                    .font(.title3)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.move(edge: .leading))
                        case .instructions:
                            VStack(alignment: .leading) {
                                Text(recipe.instructions ?? "")
                                    .lineSpacing(8)
                                    .font(.title3)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.move(edge: .trailing))
                        }
                    }
                    .padding([.leading, .bottom])
                    .animation(.snappy, value: selectedTab)
                }
            }
            .toolbar {
                if allowEdit {
                    NavigationLink("Edit") {
                        EditRecipeView(recipe: recipe)
                    }
                }
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
    let instructions = "Mix all ingredients until sugar is fully dissolved. Pour over ice and serve!"
    let ingredients = [
        Ingredient(name: "Lemon Juice", measurement: "1 cup"),
        Ingredient(name: "Water", measurement: "1 cup"),
        Ingredient(name: "Sugar", measurement: "2 tablespoons")
    ]
    let recipe = Recipe(id: UUID().uuidString, name: "Lemonade", category: .miscellaneous, instructions: instructions, ingredients: ingredients, calories: 100, totalCookTime: 5)
    NavigationStack {
        RecipeInfoView(recipeId: "12345", allowEdit: true, recipe: recipe)
    }
}
