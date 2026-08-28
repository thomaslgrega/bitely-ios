//
//  Type a Recipe name, get the Shared Recipes that match it. Results arrive as the user
//  types: the match is the API's, so a misspelling or half a word still lands.
//
//  Discover's Category selection is left alone underneath — a Name Query is asked of the
//  whole corpus, never of the Category the user happened to have open.
//

import SwiftData
import SwiftUI

struct RecipeNameSearchView: View {
    /// The grid's one query: every tile reads its saved state out of this.
    @Query private var localRecipes: [Recipe]

    @State private var search: RecipeNameSearch
    @FocusState private var queryFocused: Bool

    init(service: RecipeService) {
        _search = State(initialValue: RecipeNameSearch(service: service))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            queryField
            results
        }
        .padding(.top, Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.surface)
        .navigationTitle("Find a recipe")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { queryFocused = true }
    }

    private var queryField: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: SymbolSize.control, weight: .medium))
                .foregroundStyle(Color.contentSecondary)
                .accessibilityHidden(true)

            TextField(
                "Search by name, e.g. shakshuka",
                text: Binding(get: { search.query }, set: search.setQuery)
            )
            .textStyle(.body)
            .foregroundStyle(Color.contentPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .focused($queryFocused)

            if !search.query.isEmpty {
                Button {
                    search.setQuery("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: SymbolSize.control, weight: .medium))
                        .foregroundStyle(Color.contentSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear the search")
            }
        }
        .fieldSurface()
        .padding(.horizontal, Spacing.xl)
    }

    @ViewBuilder
    private var results: some View {
        switch search.state {
        case .prompt:
            EmptyState(
                systemImage: "magnifyingglass",
                title: "What are you after?",
                message: "Type the name of a dish and we'll find it in the recipes people have shared."
            )
            .frame(maxHeight: .infinity, alignment: .top)

        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxxl)
                .frame(maxHeight: .infinity, alignment: .top)

        case .results(let recipes):
            grid(of: recipes)

        case .noResults(let query):
            EmptyState(
                systemImage: "fork.knife",
                title: "No recipes named that",
                message: "Nothing shared matches \u{201C}\(query)\u{201D}. Try another spelling or a shorter name."
            )
            .frame(maxHeight: .infinity, alignment: .top)

        case .failed:
            EmptyState(
                systemImage: "wifi.slash",
                title: "Couldn't search",
                message: "Check your connection and try again.",
                actionTitle: "Try again"
            ) {
                search.retry()
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    /// The API's order is the ranking — closest match first — so the grid renders the list
    /// as it arrives and sorts nothing.
    private func grid(of recipes: [RecipeSummaryDTO]) -> some View {
        let held = HeldRecipes(localRecipes)
        return ScrollView {
            RecipeGrid(items: recipes) { recipe in
                SavableRecipeTile(recipe: recipe, held: held)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxxl)
        }
    }
}

#Preview {
    NavigationStack {
        RecipeNameSearchView(service: RecipeService(api: APIClient(authStore: AuthStore())))
    }
    .previewStores()
    .modelContainer(for: Recipe.self, inMemory: true)
}
