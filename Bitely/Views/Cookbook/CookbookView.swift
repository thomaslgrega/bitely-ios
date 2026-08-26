import SwiftData
import SwiftUI

enum CookbookDestination: Hashable {
    case recipe(Recipe)
    case newRecipe(Recipe)
    /// A Shared Recipe this user wrote elsewhere: the device has only its summary, so the
    /// detail screen fetches it the same way Discover does.
    case sharedRecipe(String)
}

/// Everything on the device, split by authorship — docs/design/app-flow.md, Cookbook.
struct CookbookView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(Cookbook.self) private var cookbook
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Recipe.name)]) private var recipes: [Recipe]

    @State private var destination: CookbookDestination?

    private var entries: [CookbookEntry] {
        cookbook.entries(in: cookbook.segment, from: recipes)
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
                case .sharedRecipe(let id): RemoteRecipeInfoView(recipeId: id, allowEdit: false)
                }
            }
            .task { await cookbook.loadAuthorship() }
            // Signing in from the Share action's auth sheet is what fills My Recipes with
            // the Shared Recipes written on another device, so the segment reloads on it.
            .onChange(of: authStore.isAuthenticated) { _, _ in
                Task { await cookbook.loadAuthorship() }
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
        if entries.isEmpty {
            emptyState
        } else {
            RecipeGrid(items: entries) { entry in
                tile(for: entry)
            }
        }
    }

    /// The heart sits beside the tile rather than inside it: the whole tile is already a
    /// button, and a button nested in another button does not reliably take its own taps.
    /// It is offered only over a Saved Recipe — there is no un-saving one's own work.
    private func tile(for entry: CookbookEntry) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                destination = destination(for: entry)
            } label: {
                RecipeTile(recipe: entry.summary)
            }
            .buttonStyle(.plain)

            if case .local(let recipe) = entry, cookbook.segment(for: recipe) == .saved {
                SaveButton(
                    isSaved: true,
                    onSave: {},
                    onUnsave: { cookbook.unsave(recipe, from: modelContext) }
                )
                .padding(Spacing.s)
            }
        }
    }

    private func destination(for entry: CookbookEntry) -> CookbookDestination {
        switch entry {
        case .local(let recipe): .recipe(recipe)
        case .shared(let summary): .sharedRecipe(summary.id)
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
    CookbookView()
        .previewStores()
        .modelContainer(for: Recipe.self, inMemory: true)
}
