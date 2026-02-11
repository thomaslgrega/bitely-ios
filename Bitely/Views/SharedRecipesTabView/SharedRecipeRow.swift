//
//  SharedRecipeRow.swift
//  Bitely
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
    @State private var recipeSelected = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.title2)
                    .lineLimit(1)
                    .foregroundStyle(Color.secondary700)
                Text(recipe.category.rawValue)
                    .font(.headline)
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
                        .font(.title3)
                        .foregroundStyle(Color.primaryMain)
                }
            }
            .disabled(deleteInProgress)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(minHeight: 50)
        .background(Color.secondary100)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary200, lineWidth: 1)
        )
        .alert("Are you sure?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteRecipe()
                }
            }
        }
        .onTapGesture {
            recipeSelected = true
        }
        .navigationDestination(isPresented: $recipeSelected) {
            RemoteRecipeInfoView(recipeId: recipe.id, allowEdit: true)
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
