import SwiftData
import SwiftUI

enum CookbookDestination: Hashable {
    case recipe(Recipe)
    case newRecipe(Recipe)
}

/// Everything on the device, split by authorship — docs/design/app-flow.md, Cookbook.
struct CookbookView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(Cookbook.self) private var cookbook
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Recipe.name)]) private var recipes: [Recipe]

    @State private var destination: CookbookDestination?

    private var visibleRecipes: [Recipe] {
        cookbook.recipes(in: cookbook.segment, from: recipes)
    }

    var body: some View {
        @Bindable var cookbook = cookbook

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    CustomSegmentedControl(
                        selection: $cookbook.segment,
                        options: CookbookSegment.allCases.map { ($0, $0.rawValue) }
                    )

                    contents
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.surface)
            .navigationTitle("Cookbook")
            .toolbar { newRecipeButton }
            .navigationDestination(item: $destination) { destination in
                switch destination {
                case .newRecipe(let recipe): EditRecipeView(recipe: recipe)
                case .recipe(let recipe): LocalRecipeInfoView(recipe: recipe, allowEdit: true)
                }
            }
            .task { await cookbook.loadAuthorship() }
            .onChange(of: authStore.isAuthenticated) { _, signedIn in
                cookbook.forgetAuthorship()
                if signedIn {
                    Task { await cookbook.loadAuthorship() }
                }
            }
            // The chosen segment only changes which Recipes pass the filter, so the swap
            // animates here rather than inside the control's own transaction.
            .animation(.snappy, value: cookbook.segment)
        }
    }

    /// One `+`, on My Recipes, always making a Private Recipe: it never publishes and never
    /// asks about publishing, so there is no way to share something by accident.
    @ToolbarContentBuilder
    private var newRecipeButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if cookbook.segment == .myRecipes {
                Button {
                    destination = .newRecipe(Recipe(name: "", category: .other))
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New recipe")
            }
        }
    }

    @ViewBuilder
    private var contents: some View {
        if visibleRecipes.isEmpty {
            emptyState
        } else {
            RecipeGrid(items: visibleRecipes) { recipe in
                tile(for: recipe)
            }
        }
    }

    /// The heart sits beside the tile rather than inside it: the whole tile is already a
    /// button, and a button nested in another button does not reliably take its own taps.
    private func tile(for recipe: Recipe) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                destination = .recipe(recipe)
            } label: {
                RecipeTile(recipe: RecipeSummary(recipe))
            }
            .buttonStyle(.plain)

            if cookbook.segment(for: recipe) == .saved {
                SaveButton(
                    isSaved: true,
                    onSave: {},
                    onUnsave: { cookbook.unsave(recipe, from: modelContext) }
                )
                .padding(Spacing.s)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch cookbook.segment {
        case .myRecipes:
            EmptyState(
                systemImage: "book.closed",
                title: "Nothing written yet",
                message: "Recipes you write land here, private until you share them.",
                actionTitle: "Write a recipe"
            ) {
                destination = .newRecipe(Recipe(name: "", category: .other))
            }

        case .saved:
            EmptyState(
                systemImage: "heart",
                title: "Nothing saved yet",
                message: "Recipes you save from other people land here."
            )
        }
    }
}

#Preview {
    let authStore = AuthStore()
    let service = RecipeService(api: APIClient(authStore: authStore))
    CookbookView()
        .environment(authStore)
        .environment(service)
        .environment(Cookbook(service: service, authStore: authStore))
        .modelContainer(for: Recipe.self, inMemory: true)
}
