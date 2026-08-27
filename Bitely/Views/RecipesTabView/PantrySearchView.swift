//
//  Enter the foods you have on hand, get back the Recipes you could cook with
//  them, best fit first.
//
//  Two searches feed one list: the SwiftData store — Private Recipes and Saved
//  Recipes alike — matched on the device, and the corpus of Shared Recipes
//  matched by the API. The local half needs no network, so losing the corpus
//  narrows the list rather than emptying it, and the screen says so.
//

import SwiftData
import SwiftUI

struct PantrySearchView: View {
    /// Every Recipe in the local store, which is exactly the user's Private
    /// Recipes and their Saved Recipes.
    @Query(sort: [SortDescriptor(\Recipe.name)]) private var recipes: [Recipe]

    @Environment(RecipeService.self) private var recipeService

    @State private var search = PantrySearch()
    @FocusState private var draftFocused: Bool

    /// The stored Recipe behind each local Match, so tapping one opens it in full.
    private var recipesByID: [String: Recipe] {
        Dictionary(recipes.map { ($0.id.uuidString, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// The ids each stored Recipe answers to, keyed the way its local Match is,
    /// so the merge can recognize a Saved Recipe in the corpus half.
    private var localIdentities: [String: [String]] {
        Dictionary(
            recipes.map { ($0.id.uuidString, $0.matchIdentities) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            entryField

            if !search.pantryItems.isEmpty {
                pantryItemChips
            }

            searchButton

            foundRecipes
        }
        .padding(.top, Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.surface)
        .navigationTitle("Cook what you have")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Entering Pantry Items

    private var entryField: some View {
        HStack(spacing: Spacing.m) {
            TextField("Add a food you have, e.g. eggs", text: $search.draft)
                .textStyle(.body)
                .foregroundStyle(Color.contentPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($draftFocused)
                .onSubmit(commitDraft)

            Button(action: commitDraft) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: SymbolSize.control, weight: .medium))
                    .foregroundStyle(Color.accent)
            }
            .buttonStyle(.plain)
            .disabled(!search.canCommit)
            .opacity(search.canCommit ? 1 : 0.4)
            .accessibilityLabel("Add this food")
        }
        .fieldSurface()
        .padding(.horizontal, Spacing.xl)
    }

    /// The rail bleeds past the page margin the way Discover's chip rail does, so a long
    /// Pantry scrolls to the screen edge rather than stopping short of it.
    private var pantryItemChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(search.pantryItems, id: \.self) { item in
                    Button {
                        withAnimation(.snappy) { search.remove(item) }
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Text(item)
                                .textStyle(.label)
                            Image(systemName: "xmark.circle.fill")
                        }
                        .chipFace()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(item)")
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    private var searchButton: some View {
        Button("Find recipes") {
            draftFocused = false
            Task {
                await search.search(
                    in: recipes.map(MatchableRecipe.init),
                    localIdentities: localIdentities,
                    corpus: recipeService
                )
            }
        }
        .buttonStyle(.primary)
        .disabled(!search.canSearch)
        .padding(.horizontal, Spacing.xl)
    }

    private func commitDraft() {
        search.commitDraft()
        draftFocused = true
    }

    // MARK: - Matches

    @ViewBuilder
    private var foundRecipes: some View {
        switch search.state {
        case .idle:
            EmptyState(
                systemImage: "carrot",
                title: "What's in the kitchen?",
                message: "Add the foods you have on hand and we'll find the recipes you can cook — yours and everyone else's."
            )
            .frame(maxHeight: .infinity, alignment: .top)

        case .noMatches:
            VStack(alignment: .leading, spacing: Spacing.s) {
                corpusNotice

                EmptyState(
                    systemImage: "magnifyingglass",
                    title: "Nothing matches yet",
                    message: "Nothing we can find uses what you have. Try adding another food."
                )
            }
            .frame(maxHeight: .infinity, alignment: .top)

        case .matches(let matches):
            VStack(alignment: .leading, spacing: Spacing.s) {
                corpusNotice

                ScrollView {
                    LazyVStack(spacing: Spacing.m) {
                        ForEach(matches) { match in
                            matchLink(match)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
        }
    }

    /// A Match leads to the Recipe it came from: the stored copy for a local
    /// Match, the corpus Recipe for a Shared one. A local Match the store cannot
    /// name is still a Match, so it is shown; it just has nothing to open.
    ///
    /// The destination is pushed directly rather than registered by value type,
    /// as the rest of the app pushes a Recipe. Two type-based destinations
    /// declared in a view that is itself pushed collide with the stack's
    /// existing registrations.
    @ViewBuilder
    private func matchLink(_ match: PantryMatch) -> some View {
        switch match.source {
        case .local:
            if let recipe = recipesByID[match.id] {
                NavigationLink {
                    LocalRecipeInfoView(recipe: recipe, allowEdit: true)
                } label: {
                    PantryMatchRow(match: match.match)
                }
                .buttonStyle(.plain)
            } else {
                PantryMatchRow(match: match.match)
            }

        case .corpus:
            NavigationLink {
                RemoteRecipeInfoView(recipeId: match.id, allowEdit: false)
            } label: {
                PantryMatchRow(match: match.match)
            }
            .buttonStyle(.plain)
        }
    }

    /// What the corpus half of the search is doing. The local Matches are on
    /// show either way, so this qualifies the list rather than replacing it.
    @ViewBuilder
    private var corpusNotice: some View {
        if search.awaitingCorpus {
            HStack(spacing: Spacing.s) {
                ProgressView()
                Text("Looking for shared recipes\u{2026}")
            }
            .textStyle(.meta)
            .foregroundStyle(Color.contentSecondary)
            .padding(.horizontal, Spacing.xl)
        } else if search.localOnly {
            Label(
                "We couldn't reach shared recipes, so these are the ones on your device.",
                systemImage: "wifi.slash"
            )
            .textStyle(.meta)
            .foregroundStyle(Color.contentSecondary)
            .padding(.horizontal, Spacing.xl)
        }
    }
}

#Preview {
    NavigationStack {
        PantrySearchView()
    }
    .previewStores()
}
