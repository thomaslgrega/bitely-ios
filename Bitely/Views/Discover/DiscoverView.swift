import SwiftUI

/// The front door: greeting, the Pantry Search promo, the chip rail and Today's Picks —
/// docs/design/app-flow.md, Discover.
struct DiscoverView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(RecipeStore.self) private var store

    @State private var showSettings = false
    @State private var showPantrySearch = false

    private var greeting: Greeting { Greeting(user: authStore.user) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    greetingBar
                    pantryPromo
                    chipRail
                    picks
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.surface)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showPantrySearch) { PantrySearchView() }
            .navigationDestination(for: RecipeSummaryDTO.self) { recipe in
                RemoteRecipeInfoView(recipeId: recipe.id, allowEdit: false)
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task { await store.loadFeed() }
        }
    }

    private var greetingBar: some View {
        GreetingBar(greeting: greeting.salutation, name: greeting.name) {
            showSettings = true
        } trailing: {
            EmptyView()
        }
        .padding(.top, Spacing.m)
    }

    private var pantryPromo: some View {
        PromoCard(
            heading: "Cook what\nyou have",
            subcopy: "Search your recipes and shared\nones by the foods on hand",
            actionTitle: "Start searching",
            imageName: "vegetarian"
        ) {
            showPantrySearch = true
        }
    }

    private var chipRail: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("Browse by category")
            ChipRail(categories: FoodCategory.allCases, selection: selection)
        }
    }

    /// The rail writes a selection; the store answers it with at most one request, so the
    /// binding hands it straight over rather than holding a copy the two could disagree on.
    private var selection: Binding<FoodCategory?> {
        Binding(
            get: { store.selectedCategory },
            set: { category in Task { await store.select(category) } }
        )
    }

    private var picks: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            SectionHeader(store.heading)
            grid
        }
        // The chip's tap only starts the store's work, so the swap animates on the
        // selection landing rather than inside the rail's own transaction.
        .animation(.snappy, value: store.selectedCategory)
    }

    @ViewBuilder
    private var grid: some View {
        switch store.contents(on: Date()) {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxxl)

        case .failed:
            EmptyState(
                systemImage: "wifi.slash",
                title: "Couldn't load recipes",
                message: "Check your connection and try again.",
                actionTitle: "Try again"
            ) {
                Task { await store.retry() }
            }

        case .recipes(let recipes) where recipes.isEmpty:
            EmptyState(
                systemImage: "fork.knife",
                title: "Nothing here yet",
                message: "Recipes people share show up here."
            )

        case .recipes(let recipes):
            RecipeGrid(items: recipes) { recipe in
                NavigationLink(value: recipe) {
                    RecipeTile(recipe: RecipeSummary(recipe))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    let authStore = AuthStore()
    DiscoverView()
        .environment(authStore)
        .environment(RecipeStore(service: RecipeService(api: APIClient(authStore: authStore))))
}
