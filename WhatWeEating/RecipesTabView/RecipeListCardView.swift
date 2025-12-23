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
    @Environment(\.modelContext) var modelContext
    let recipe: Recipe
    @Query(sort: [SortDescriptor(\Recipe.strMeal)]) var savedRecipes: [Recipe]
    @State private var bookmarkingInProgress = false
    @State private var vm = RecipesTabViewVM()
    @State private var showDeleteAlert = false

    var isBookmarked: Bool {
        savedRecipes.contains(where: { $0.id == recipe.id })
    }

    var savedRecipe: Recipe? {
        savedRecipes.first(where: { $0.id == recipe.id })
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

            if let imageURL = recipe.strMealThumb {
                KFImage(URL(string: imageURL))
                    .resizable()
                    .downsampling(size: CGSize(width: 250, height: 250))
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
            } else {
                Image(recipe.strCategory?.lowercased() ?? "photo")
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
            }
        }
        .alert("Are you sure?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: deleteRecipe)
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

        if let fullRecipe = await vm.fetchRecipeById(id: recipe.id) {
            modelContext.insert(fullRecipe)
        }

        bookmarkingInProgress = false
    }

    func deleteRecipe() {
        bookmarkingInProgress = true

        if let recipeToDelete = savedRecipe {
            modelContext.delete(recipeToDelete)
        }

        bookmarkingInProgress = false
    }
}

#Preview {
    RecipeListCardView(recipe: Recipe(id: "123", strMeal: "Spaghetti and Meatballs", strCategory: "Pasta", strMealThumb: nil, calories: nil, totalCookTime: nil))

}
