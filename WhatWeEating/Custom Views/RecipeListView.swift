//
//  RecipeListView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/29/25.
//

import SwiftUI
import Kingfisher

struct RecipeListView: View {
    @Environment(\.modelContext) var modelContext
    let selectedCategory: FoodCategories?

//    @Binding var vm: RecipesTabViewVM
    @State var vm = RecipesTabViewVM()

    var body: some View {
        List(vm.recipes) { recipe in
            NavigationLink(value: recipe) {
                HStack {
                    KFImage(URL(string: recipe.strMealThumb))
                        .resizable()
                        .frame(width: 64, height: 64)
                    Text(recipe.strMeal)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(selectedCategory?.rawValue ?? "")
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeInfoView(recipeId: recipe.id, vm: $vm)
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
