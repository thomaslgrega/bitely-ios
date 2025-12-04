//
//  RecipeListView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/29/25.
//

import SwiftData
import SwiftUI
import Kingfisher

struct RecipeListView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\Recipe.strMeal)]) var savedRecipes: [Recipe]

    var savedRecipeIds: Set<String> {
        Set(savedRecipes.map { $0.id })
    }

    let selectedCategory: FoodCategories?
    @State var vm = RecipesTabViewVM()

    var body: some View {
        List(vm.recipes) { recipe in
            NavigationLink(value: recipe) {
                HStack {
                    if let imageURL = recipe.strMealThumb {
                        KFImage(URL(string: imageURL))
                            .resizable()
                            .frame(width: 64, height: 64)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .frame(width: 64, height: 64)
                    }
                    Text(recipe.strMeal)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(selectedCategory?.rawValue ?? "")
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeInfoView(savedRecipeIds: savedRecipeIds, recipeId: recipe.id)
        }
        .task {
            if let selectedCategory {
                await vm.fetchRecipesByCategory(category: selectedCategory)
            }
        }
    }
}

#Preview {
    RecipeListView(selectedCategory: .Beef)
}
