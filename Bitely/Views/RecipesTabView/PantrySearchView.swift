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
        VStack(alignment: .leading, spacing: 16) {
            entryField

            if !search.pantryItems.isEmpty {
                pantryItemChips
            }

            searchButton

            foundRecipes
        }
        .padding(.top)
        .navigationTitle("Cook what you have")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Entering Pantry Items

    private var entryField: some View {
        HStack {
            TextField("Add a food you have, e.g. eggs", text: $search.draft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($draftFocused)
                .onSubmit {
                    search.commitDraft()
                    draftFocused = true
                }

            Button {
                search.commitDraft()
                draftFocused = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.primaryMain)
            }
            .disabled(!search.canCommit)
        }
        .padding()
        .background(Color.secondary100)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary200, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var pantryItemChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(search.pantryItems, id: \.self) { item in
                    Button {
                        search.remove(item)
                    } label: {
                        HStack(spacing: 4) {
                            Text(item)
                            Image(systemName: "xmark.circle.fill")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary700)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.primary100)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(item)")
                }
            }
            .padding(.horizontal)
        }
    }

    private var searchButton: some View {
        Button {
            draftFocused = false
            Task {
                await search.search(
                    in: recipes.map(MatchableRecipe.init),
                    localIdentities: localIdentities,
                    corpus: recipeService
                )
            }
        } label: {
            Text("Find recipes")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(search.canSearch ? Color.primaryMain : Color.secondary200)
                .foregroundStyle(search.canSearch ? Color.secondary50 : Color.secondary400)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!search.canSearch)
        .padding(.horizontal)
    }

    // MARK: - Matches

    @ViewBuilder
    private var foundRecipes: some View {
        switch search.state {
        case .idle:
            message("Add the foods you have on hand and we'll find the recipes you can cook — yours and everyone else's.")

        case .noMatches:
            VStack(alignment: .leading, spacing: 8) {
                corpusNotice
                message("Nothing we can find uses what you have. Try adding another food.")
            }

        case .matches(let matches):
            VStack(alignment: .leading, spacing: 8) {
                corpusNotice

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(matches) { match in
                            matchLink(match)
                        }
                    }
                    .padding(.horizontal)
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
            HStack(spacing: 8) {
                ProgressView()
                Text("Looking for shared recipes\u{2026}")
            }
            .font(.subheadline)
            .foregroundStyle(Color.secondary700)
            .padding(.horizontal)
        } else if search.localOnly {
            Label(
                "We couldn't reach shared recipes, so these are the ones on your device.",
                systemImage: "wifi.slash"
            )
            .font(.subheadline)
            .foregroundStyle(Color.secondary700)
            .padding(.horizontal)
        }
    }

    private func message(_ text: String) -> some View {
        VStack {
            Text(text)
                .font(.title3)
                .italic()
                .foregroundStyle(Color.secondary400)

            Spacer()
        }
        .padding()
    }
}

/// One Match: the Recipe, its Coverage as the integer pair the matcher keeps,
/// and the Missing Ingredients spelled out — an incomplete Match is the point
/// of the feature, so it says what a trip to the shop would cost.
struct PantryMatchRow: View {
    let match: RecipeMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(match.recipeName)
                .font(.title3)
                .bold()
                .foregroundStyle(Color.secondaryMain)

            Text("You have \(match.matchedCount) of \(match.totalCount) ingredients")
                .font(.subheadline)
                .foregroundStyle(Color.secondary700)

            if match.missingIngredients.isEmpty {
                Text("You have everything")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentMain)
            } else {
                Text("Missing: \(match.missingIngredients.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary400)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary100)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary200, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        PantrySearchView()
    }
}
