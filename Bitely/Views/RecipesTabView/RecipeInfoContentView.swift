//
//  RecipeInfoContentView.swift
//  Bitely
//
//  Created by Thomas Grega on 2/2/26.
//

import SwiftUI

enum RecipeTab {
    case ingredients
    case instructions
}

struct RecipeInfoContentView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(RecipeService.self) private var recipeService

    let recipe: Recipe
    let allowEdit: Bool
    let isSaved: Bool
    let onToggleBookmark: () -> Void

    @State private var showDeleteAlert = false
    @State private var showShareAlert = false
    @State private var showAuthSheet = false
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
                            isSaved ? showDeleteAlert = true : onToggleBookmark()
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

                HStack(spacing: 24) {
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
                            Text("Add to")
                        }
                        .foregroundStyle(Color.primaryMain)
                    }

                    Button {
                        if authStore.isAuthenticated {
                            showShareAlert = true
                        } else {
                            showAuthSheet = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .foregroundStyle(Color.primaryMain)
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
        .alert("Do you want to share this recipe?", isPresented: $showShareAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Share") {
                Task {
                    do {
                        let ingredients = recipe.ingredients.map { CreateIngredientRequest(name: $0.name, measurement: $0.measurement) }
                        _ = try await recipeService.createRecipe(recipe: CreateRecipeRequest(
                            name: recipe.name,
                            category: recipe.category,
                            instructions: recipe.instructions,
                            thumbnailUrl: recipe.thumbnailURL,
                            ingredients: ingredients,
                            calories: recipe.calories,
                            totalCookTime: recipe.totalCookTime
                        ))
                    } catch {
                        print("Failed to share recipe:", error)
                    }
                }
            }
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthSheet()
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
        recipe: Recipe(name: "Lemonade", category: .other),
        allowEdit: false,
        isSaved: true,
        onToggleBookmark: {}
    )
}
