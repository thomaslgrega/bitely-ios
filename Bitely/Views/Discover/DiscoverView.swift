import SwiftData
import SwiftUI

/// The front door: greeting, the Pantry Search promo, the chip rail and Today's Picks —
/// docs/design/app-flow.md, Discover.
struct DiscoverView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(RecipeService.self) private var recipeService
    @Environment(RecipeStore.self) private var store
    @Environment(Cookbook.self) private var cookbook
    /// The grid's one query: every tile reads its saved state out of this.
    @Query private var localRecipes: [Recipe]

    @State private var showSettings = false
    @State private var showPantrySearch = false
    @State private var showNameSearch = false

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
            .navigationDestination(isPresented: $showNameSearch) {
                RecipeNameSearchView(service: recipeService)
            }
            .navigationDestination(for: RecipeSummaryDTO.self) { recipe in
                RemoteRecipeInfoView(recipeId: recipe.id, allowEdit: false)
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task { await store.loadFeed() }
            // Which tiles offer a heart turns on authorship, so the grid asks for it the
            // same way the Cookbook does.
            .task { await cookbook.loadAuthorship() }
            .onChange(of: authStore.isAuthenticated) { _, _ in
                Task { await cookbook.loadAuthorship() }
            }
        }
    }

    private var greetingBar: some View {
        GreetingBar(greeting: greeting.salutation, name: greeting.name) {
            showSettings = true
        } trailing: {
            // Deliberately lighter than the Pantry promo: the two answer different
            // questions, and a name search is the one iOS users look for up here.
            CircleIconButton(systemImage: "magnifyingglass", accessibilityLabel: "Search recipes by name") {
                showNameSearch = true
            }
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
            // Built once for the grid rather than per tile, which is the whole point of
            // answering fifty tiles from one query.
            let held = HeldRecipes(localRecipes)
            RecipeGrid(items: recipes) { recipe in
                SavableRecipeTile(recipe: recipe, held: held)
            }
        }
    }
}

#Preview {
    DiscoverView()
        .previewStores()
        .modelContainer(for: Recipe.self, inMemory: true)
}
