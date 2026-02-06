//
//  RecipeListViewCard.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/18/25.
//

import Kingfisher
import SwiftData
import SwiftUI

struct RecipeListCardView: View {
    @Environment(RecipeService.self) private var recipeService
    @Environment(\.modelContext) var modelContext

    let recipe: RecipeSummary
    @Query private var savedRecipes: [Recipe]
    @State private var bookmarkingInProgress = false
    @State private var showDeleteAlert = false

    var isBookmarked: Bool {
        guard let rid = recipe.remoteId else { return true }
        return savedRecipes.contains(where: { $0.remoteId == rid || $0.id.uuidString == recipe.id })
    }

    var savedRecipe: Recipe? {
        savedRecipes.first(where: { $0.remoteId == recipe.id || $0.id.uuidString == recipe.id })
    }

    var body: some View {
        VStack {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.primaryMain)
                    Text(recipe.calories.map { "\($0) cals" } ?? "N/A")
                        .foregroundStyle(Color.secondaryMain)
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.secondary200))

                Spacer()

                HStack {
                    Button {
                        Task {
                            isBookmarked ? showDeleteAlert = true : await bookmarkRecipe()
                        }
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(Color.primaryMain)
                    }
                    .disabled(bookmarkingInProgress)
                }
                .font(.subheadline)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.secondary200))
            }
            .padding([.top, .horizontal], 12)

            recipeImage
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
        }
        .alert("Are you sure?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: unbookmarkRecipe)
        }
        .background(Color.secondary100)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary200, lineWidth: 1)
        )
    }

    func bookmarkRecipe() async {
        bookmarkingInProgress = true
        defer {
            bookmarkingInProgress = false
        }

        do {
            let fullRecipe = try await recipeService.getRecipeById(id: recipe.id)
            let swiftDataRecipe = Recipe(
                remoteId: fullRecipe.id,
                name: fullRecipe.name,
                category: fullRecipe.category,
                instructions: fullRecipe.instructions,
                thumbnailURL: fullRecipe.thumbnailUrl,
                calories: fullRecipe.calories,
                totalCookTime: fullRecipe.totalCookTime
            )

            swiftDataRecipe.ingredients = fullRecipe.ingredients.map {
                Ingredient(name: $0.name, measurement: $0.measurement)
            }

            modelContext.insert(swiftDataRecipe)
        } catch {
            print("Bookmark failed:", error)
        }
    }

    func unbookmarkRecipe() {
        bookmarkingInProgress = true

        if let recipeToDelete = savedRecipe {
            modelContext.delete(recipeToDelete)
        }

        bookmarkingInProgress = false
    }

    @ViewBuilder
    private var recipeImage: some View {
        if let data = recipe.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
        } else if let imageURL = recipe.thumbnailUrl, let url = URL(string: imageURL) {
            KFImage(url)
                .resizable()
                .downsampling(size: CGSize(width: 250, height: 250))
        } else {
            Image(recipe.category.rawValue.lowercased())
                .resizable()
        }
    }
}

#Preview {
    let recipe = Recipe(name: "Spaghetti and Meatballs", category: .pasta, thumbnailURL: nil, calories: nil, totalCookTime: nil)
    let summary = RecipeSummary(id: recipe.id.uuidString, remoteId: recipe.remoteId, name: recipe.name, category: recipe.category, thumbnailUrl: recipe.thumbnailURL, imageData: recipe.imageData, calories: recipe.calories, totalCookTime: recipe.totalCookTime)
    RecipeListCardView(recipe: summary)

}
