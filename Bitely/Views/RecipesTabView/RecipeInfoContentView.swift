import SwiftUI

enum RecipeTab {
    case ingredients
    case instructions
}

struct RecipeInfoContentView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(Cookbook.self) private var cookbook

    let recipe: Recipe
    let allowEdit: Bool
    let isSaved: Bool
    let onToggleBookmark: () -> Void

    @State private var showShareAlert = false
    @State private var showAuthSheet = false
    @State private var selectedTab: RecipeTab = .ingredients

    private var shareControl: ShareControl {
        ShareControl(
            recipe: recipe,
            isAuthenticated: authStore.isAuthenticated,
            shareState: cookbook.shareState(of: recipe)
        )
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
            Button("Share") { cookbook.beginShare(recipe) }
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
    /// Fitted rather than filled: this is the one screen that shows a Recipe's photo whole,
    /// and a portrait shot cropped to a band loses what the user attached it for.
    private var picture: some View {
        RecipeImageView(recipe: recipe)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
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

    /// A Recipe carrying neither number gets no row at all, rather than the gap an empty
    /// `HStack` would leave between the name and the actions.
    @ViewBuilder
    private var meta: some View {
        if recipe.totalCookTime != nil || recipe.calories != nil {
            HStack(spacing: Spacing.xl) {
                MetaLabel.cookTime(minutes: recipe.totalCookTime)
                MetaLabel.calories(recipe.calories)
            }
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
                    Label(shareControl.label, systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.secondary)
                .disabled(!shareControl.isEnabled)
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
        case .share: cookbook.beginShare(recipe)
        case .presentAuth: showAuthSheet = true
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
