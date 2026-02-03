//
//  SharedRecipesView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 1/29/26.
//

import SwiftUI

struct SharedRecipesView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(RecipeService.self) private var recipeService

    @State private var showAuthSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var recipes: [RecipeSummaryDTO] = []

    var body: some View {
        NavigationStack {
            Group {
                if !authStore.isAuthenticated {
                    VStack(spacing: 12) {
                        Text("Sign in to view your shared recipes.")
                        Button("Sign In") { showAuthSheet = true }
                    }
                    .padding()
                } else {
                    List(recipes) { recipe in
                        SharedRecipeRow(recipe: recipe)
                    }
                    .overlay {
                        if isLoading { ProgressView() }
                    }
                }
            }
            .navigationTitle("Shared")
            .toolbar {
                if authStore.isAuthenticated {
                    Button("Refresh") {
                        Task {
                            await load()
                        }
                    }
                }
            }
            .sheet(isPresented: $showAuthSheet) {
                AuthSheet()
            }
            .task {
                if authStore.isAuthenticated {
                    await load()
                }
            }
            .onChange(of: authStore.isAuthenticated) { _, loggedIn in
                if loggedIn {
                    Task {
                        await load()
                    }
                } else {
                    recipes = []
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
        }

        do {
            recipes = try await recipeService.getSharedRecipes()
        } catch {
            errorMessage = "Failed to load shared recipes."
        }
    }
}

struct SharedRecipeRow: View {
    let recipe: RecipeSummaryDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recipe.name)
                .font(.headline)
            Text(recipe.category.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SharedRecipesView()
}
