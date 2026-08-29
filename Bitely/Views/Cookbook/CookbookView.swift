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
    /// The query is the view's, not the store's: `Cookbook` outlives the screen, and coming
    /// back to a Cookbook still trimmed by a forgotten query would look like lost Recipes.
    @State private var query = ""

    private var entries: [CookbookEntry] {
        cookbook.entries(in: cookbook.segment, from: recipes, matching: query)
    }

    private var otherSegment: CookbookSegment { cookbook.segment.other }

    /// The counts the screen turns on, gathered once: what the segment holds, what the
    /// query leaves of it, and what the same query finds one segment over — which is what
    /// keeps a correct spelling from being a dead end while the filter stays scoped.
    private var screen: CookbookScreen {
        CookbookScreen(
            segment: cookbook.segment,
            query: query,
            matches: entries.count,
            held: cookbook.entries(in: cookbook.segment, from: recipes).count,
            matchesElsewhere: cookbook.entries(in: otherSegment, from: recipes, matching: query).count,
            hasResolvedAuthorship: cookbook.hasResolvedAuthorship
        )
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

                    // Below the segments, not above: the position is what says the filter
                    // covers the open half rather than the whole Cookbook — #48.
                    if screen.offersFilter {
                        SearchField(text: $query, prompt: "Search your recipes")
                    }

                    contents
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .scrollDismissesKeyboard(.immediately)
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
        // On the stack rather than its root, so pushing a Recipe keeps the query and only
        // leaving the tab drops it.
        .onDisappear { query = "" }
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
        switch screen.placeholder {
        case .grid:
            RecipeGrid(items: entries) { entry in
                tile(for: entry)
            }

        case .emptyCollection:
            emptyState

        // Filtered to nothing, as opposed to empty: it names the query back so the user
        // can see their own spelling, and offers no way to write a Recipe, because someone
        // hunting for one did not ask to author one.
        case .matchesElsewhere(let count):
            EmptyState(
                systemImage: "fork.knife",
                title: "Not in \(cookbook.segment.rawValue)",
                message: crossSegmentMessage(count),
                actionTitle: "Look in \(otherSegment.rawValue)"
            ) {
                cookbook.segment = otherSegment
            }

        // The Shared Recipes this user wrote elsewhere are not in `entries` yet, so saying
        // nothing matches would deny a Recipe they know they wrote. That fetch may have
        // failed rather than be running, so the copy claims neither.
        case .unresolvedAuthorship:
            EmptyState(
                systemImage: "icloud.slash",
                title: "Can't check all of your recipes",
                message: "Nothing on this device matches \u{201C}\(query)\u{201D}. The recipes you wrote elsewhere aren't here yet."
            )

        case .noMatches:
            EmptyState(
                systemImage: "fork.knife",
                title: "No recipes named that",
                message: "Nothing in your cookbook matches \u{201C}\(query)\u{201D}."
            )
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

    private func crossSegmentMessage(_ count: Int) -> String {
        let subject = count == 1 ? "One recipe" : "\(count) recipes"
        let verb = count == 1 ? "matches" : "match"
        return "\(subject) in \(otherSegment.rawValue) \(verb) \u{201C}\(query)\u{201D}."
    }
}

#Preview {
    CookbookView()
        .previewStores()
        .modelContainer(for: Recipe.self, inMemory: true)
}
