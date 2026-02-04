//
//  RecipeInfoContentView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 2/2/26.
//

import SwiftUI

enum RecipeTab {
    case ingredients
    case instructions
}

struct RecipeInfoContentView: View {
    let recipe: Recipe
    let allowEdit: Bool
    let isSaved: Bool
    let onToggleBookmark: () -> Void

    @State private var showDeleteAlert = false
    @State private var selectedTab: RecipeTab = .ingredients
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                ZStack(alignment: .topTrailing) {
                    RecipeImageView(recipe: recipe)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)

                    ZStack {
                        Circle()
                            .frame(width: 50, height: 50)
                            .padding()

                        Button {
                            showDeleteAlert = true
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
                    .padding(.horizontal)

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
                        Text(recipe.totalCookTime.map { "\($0) min"} ?? "N/A")
                            .foregroundStyle(Color.secondaryMain)
                    }

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
                                    Text(ingredient.measurement).bold()
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
        .alert("Are you sure?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onToggleBookmark)
        }
        .toolbar {
            if allowEdit {
                NavigationLink("Edit") {
                    EditRecipeView(recipe: recipe)
                }
            }
        }
    }
}

#Preview {
    RecipeInfoContentView(
        recipe: Recipe(name: "Lemonade", category: .miscellaneous),
        allowEdit: false,
        isSaved: true,
        onToggleBookmark: {}
    )
}
