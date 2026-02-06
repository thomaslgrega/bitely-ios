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

    @State private var deleteInProgress = false

    var body: some View {
        NavigationStack {
            Group {
                if !authStore.isAuthenticated {
                    VStack(spacing: 12) {
                        Text("Sign in to view your shared recipes.")
                            .foregroundStyle(Color.secondaryMain)

                        Button("Sign In") {
                            showAuthSheet = true
                        }
                    }
                    .padding()
                } else {
                    List(recipes) { recipe in
                        NavigationLink(value: recipe) {
                            SharedRecipeRow(recipe: recipe) {
                                recipes.removeAll(where: { $0.id == recipe.id })
                            }
                        }
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
            .navigationDestination(for: RecipeSummaryDTO.self) { recipe in
                RemoteRecipeInfoView(recipeId: recipe.id, allowEdit: false)
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

#Preview {
    SharedRecipesView()
}
