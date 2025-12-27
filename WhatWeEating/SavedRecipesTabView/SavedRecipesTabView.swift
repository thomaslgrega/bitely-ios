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

    var savedRecipesId: Set<String> {
        Set(recipes.map { $0.id })
    }

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(recipes) { recipe in
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
                                selectedRecipe = .showRecipe(recipe)
                            }
                        }
                    }
                    .padding()
                    .navigationDestination(item: $selectedRecipe) { destination in
                        switch destination {
                        case .addNewRecipe(let recipe):
                            EditRecipeView(recipe: recipe)
                        case .showRecipe(let recipe):
                            RecipeInfoView(recipeId: recipe.id, allowEdit: true, recipe: recipe)
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button {
                        selectedRecipe = .addNewRecipe(Recipe(id: UUID().uuidString, name: "", calories: nil, totalCookTime: nil))
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
        }
    }

    func deleteSavedRecipe(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(recipes[index])
        }
    }
}

#Preview {
    SavedRecipesTabView()
}
