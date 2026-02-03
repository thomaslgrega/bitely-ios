//
//  RecipeListView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/29/25.
//

import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(RecipeService.self) private var recipeService

    let selectedCategory: FoodCategory?
    @State private var recipes: [RecipeSummaryDTO] = []

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(recipes) { recipe in
                    NavigationLink(value: recipe) {
                        VStack(alignment: .leading) {
                            RecipeListCardView(recipe: RecipeSummary(
                                id: recipe.id,
                                remoteId: recipe.id,
                                name: recipe.name,
                                category: recipe.category,
                                thumbnailUrl: recipe.thumbnailUrl,
                                imageData: nil,
                                calories: recipe.calories,
                                totalCookTime: recipe.totalCookTime
                            ))

                            Text(recipe.name)
                                .padding(.leading)
                                .lineLimit(1)
                                .font(.title3)
                                .bold()
                                .foregroundStyle(Color.secondaryMain)
                        }
                        .padding(.top)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(selectedCategory?.rawValue ?? "")
        .navigationDestination(for: RecipeSummaryDTO.self) { recipeSummary in
            RemoteRecipeInfoView(recipeId: recipeSummary.id, allowEdit: false)
        }
        .task {
            if let selectedCategory {
                do {
                    recipes = try await recipeService.getRecipesByCategory(category: selectedCategory)
                } catch {
                    print("Failed to fetch recipes: ", error)
                }
            }
        }
    }
}

#Preview {
    RecipeListView(selectedCategory: .beef)
}

