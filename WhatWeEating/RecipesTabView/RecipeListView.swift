//
//  RecipeListView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/29/25.
//

import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) var modelContext
    @State private var selectedRecipe: Recipe?

    let selectedCategory: FoodCategory?
    @State var vm = RecipesTabViewVM()

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(vm.recipes) { recipe in
                    VStack(alignment: .leading) {
                        RecipeListCardView(recipe: recipe)
                        Text(recipe.name)
                            .padding(.leading)
                            .lineLimit(1)
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color.secondaryMain)
                    }
                    .padding(.top)
                    .onTapGesture {
                        selectedRecipe = recipe
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(selectedCategory?.rawValue ?? "")
        .navigationDestination(item: $selectedRecipe, destination: { recipe in
            RecipeInfoView(recipeId: recipe.id, allowEdit: false)
        })
        .task {
            if let selectedCategory {
                await vm.fetchRecipesByCategory(category: selectedCategory)
            }
        }
    }
}

#Preview {
    RecipeListView(selectedCategory: .beef)
}

