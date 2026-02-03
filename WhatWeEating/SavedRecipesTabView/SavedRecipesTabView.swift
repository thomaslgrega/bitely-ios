//
//  SavedRecipesTabView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 11/28/25.
//

import SwiftData
import SwiftUI

enum RecipesDestinations: Hashable {
    case showRecipe(Recipe)
    case addNewRecipe(Recipe)
}

struct SavedRecipesTabView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\Recipe.name)]) var recipes: [Recipe]
    @State private var selectedRecipe: RecipesDestinations?

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                if recipes.isEmpty {
                    VStack {
                        Text("You have no recipes saved. Browse recipes to find a recipe or press the plus button to create your own!")
                            .font(.title2)
                            .italic()
                            .foregroundStyle(Color.secondary400)

                        Spacer()
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(recipes) { recipe in
                                VStack(alignment: .leading) {
                                    RecipeListCardView(recipe: RecipeSummary(
                                        id: recipe.id.uuidString,
                                        remoteId: recipe.remoteId,
                                        name: recipe.name,
                                        category: recipe.category,
                                        thumbnailUrl: recipe.thumbnailURL,
                                        imageData: recipe.imageData,
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
                                .onTapGesture {
                                    selectedRecipe = .showRecipe(recipe)
                                }
                            }
                        }
                        .padding()
                    }
                }

                HStack {
                    Spacer()
                    Button {
                        selectedRecipe = .addNewRecipe(Recipe(name: "", category: .beef))
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.secondary100)
                            .font(.title)
                    }
                    .frame(width: 50, height: 50)
                    .background(Color.primaryMain)
                    .clipShape(Circle())
                }
                .padding(32)
            }
            .navigationTitle("Saved Recipes")
            .navigationDestination(item: $selectedRecipe) { destination in
                switch destination {
                case .addNewRecipe(let recipe):
                    EditRecipeView(recipe: recipe)
                case .showRecipe(let recipe):
                    LocalRecipeInfoView(recipe: recipe, allowEdit: true)
                }
            }
        }
    }
}

#Preview {
    SavedRecipesTabView()
}
