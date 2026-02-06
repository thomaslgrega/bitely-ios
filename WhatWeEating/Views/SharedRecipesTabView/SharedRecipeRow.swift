//
//  SharedRecipeRow.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 2/4/26.
//

import SwiftUI


struct SharedRecipeRow: View {
    @Environment(RecipeService.self) private var recipeService
    let recipe: RecipeSummaryDTO
    let onDelete: () -> Void

    @State private var deleteInProgress = false
    @State private var showDeleteAlert = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                Text(recipe.category.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary400)
            }

            Spacer()

            Button {
                showDeleteAlert = true
            } label: {
                if deleteInProgress {
                    ProgressView()
                } else {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.primaryMain)
                        .font(.title3)
                }
            }
            .disabled(deleteInProgress)
        }
        .alert("Are you sure?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteRecipe()
                }
            }
        }
    }

    private func deleteRecipe() async {
        deleteInProgress = true
        defer {
            deleteInProgress = false
        }

        do {
            try await recipeService.deleteSharedRecipe(id: recipe.id)
            onDelete()
        } catch {
            print("Failed to delete recipe:", error)
        }
    }
}

#Preview {
    let recipe = RecipeSummaryDTO(id: "123", name: "Lemonade", category: .other, thumbnailUrl: nil, calories: 100, totalCookTime: 5)
    SharedRecipeRow(recipe: recipe, onDelete: {})
}
