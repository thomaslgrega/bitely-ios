import SwiftUI

enum RecipeTab {
    case ingredients
    case instructions
}

struct RecipeInfoContentView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(RecipeService.self) private var recipeService
    @Environment(Cookbook.self) private var cookbook

    let recipe: Recipe
    let allowEdit: Bool
    let isSaved: Bool
    let onToggleBookmark: () -> Void

    @State private var showShareAlert = false
    @State private var showAuthSheet = false
    @State private var selectedTab: RecipeTab = .ingredients

    private var shareControl: ShareControl {
        ShareControl(recipe: recipe, isAuthenticated: authStore.isAuthenticated)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                picture

                Text(recipe.name)
                    .textStyle(.display)
                    .foregroundStyle(Color.contentPrimary)

                meta

                actions

                CustomSegmentedControl(
                    selection: $selectedTab,
                    options: [
                        (.ingredients, "Ingredients"),
                        (.instructions, "Instructions")
                    ]
                )

                tabContents
                    .animation(.snappy, value: selectedTab)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.surface)
        .alert("Do you want to share this recipe?", isPresented: $showShareAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Share", action: shareRecipe)
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthSheet()
        }
        .toolbar {
            if allowEdit {
                NavigationLink("Edit") {
                    EditRecipeView(recipe: recipe)
                }
                .tint(Color.accent)
            }
        }
    }

    /// Full-bleed, so the picture takes the page margin back off the padding above it.
    private var picture: some View {
        RecipeImageView(recipe: recipe)
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .clipped()
            .overlay(alignment: .topTrailing) {
                SaveButton(
                    isSaved: isSaved,
                    onSave: onToggleBookmark,
                    onUnsave: onToggleBookmark
                )
                .padding(Spacing.m)
            }
            .padding(.horizontal, -Spacing.xl)
    }

    private var meta: some View {
        HStack(spacing: Spacing.xl) {
            MetaLabel.cookTime(minutes: recipe.totalCookTime)
            MetaLabel.calories(recipe.calories)
        }
    }

    private var actions: some View {
        HStack(spacing: Spacing.m) {
            NavigationLink {
                RecipeShoppingListView(items: recipe.ingredients)
            } label: {
                Label("Add to list", systemImage: "basket")
            }
            .buttonStyle(.secondary)

            if shareControl.isOffered {
                Button(action: share) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var tabContents: some View {
        switch selectedTab {
        case .ingredients:
            VStack(alignment: .leading, spacing: Spacing.m) {
                ForEach(recipe.ingredients) { ingredient in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                        Text(ingredient.measurement)
                            .textStyle(.label)
                            .foregroundStyle(Color.contentSecondary)

                        Text(ingredient.name)
                            .textStyle(.body)
                            .foregroundStyle(Color.contentPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.move(edge: .leading))

        case .instructions:
            Text(recipe.instructions ?? "")
                .textStyle(.body)
                .foregroundStyle(Color.contentPrimary)
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.move(edge: .trailing))
        }
    }

    /// Signed out this presents auth rather than the confirmation, so the account is asked
    /// for at the moment of sharing rather than on the way into the Cookbook.
    private func share() {
        switch shareControl.tap {
        case .confirmShare: showShareAlert = true
        case .presentAuth: showAuthSheet = true
        }
    }

    private func shareRecipe() {
        Task {
            do {
                let ingredients = recipe.ingredients.map { CreateIngredientRequest(name: $0.name, measurement: $0.measurement) }
                let remoteRecipe = try await recipeService.createRecipe(recipe: CreateRecipeRequest(
                    name: recipe.name,
                    category: recipe.category,
                    instructions: recipe.instructions,
                    thumbnailUrl: recipe.thumbnailURL,
                    ingredients: ingredients,
                    calories: recipe.calories,
                    totalCookTime: recipe.totalCookTime
                ))

                recipe.remoteId = remoteRecipe.id
                cookbook.recordAuthorship(of: remoteRecipe)
            } catch {
                print("Failed to share recipe:", error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecipeInfoContentView(
            recipe: Recipe(name: "Lemonade", category: .other),
            allowEdit: false,
            isSaved: true,
            onToggleBookmark: {}
        )
    }
    .previewStores()
}
