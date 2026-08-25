//
//  PantrySearchView.swift
//  Bitely
//
//  Enter the foods you have on hand, get back the Recipes on this device you
//  could cook with them, best fit first.
//
//  Everything the screen needs is local: the Recipes come from the SwiftData
//  store — Private Recipes and Saved Recipes alike — and the matching runs on
//  the device, so the flow works in airplane mode.
//

import SwiftData
import SwiftUI

struct PantrySearchView: View {
    /// Every Recipe in the local store, which today is exactly the user's
    /// Private Recipes and their Saved Recipes. Corpus Recipes arrive over the
    /// network and are not held here.
    @Query(sort: [SortDescriptor(\Recipe.name)]) private var recipes: [Recipe]

    @State private var search = PantrySearch()
    @FocusState private var draftFocused: Bool

    /// The stored Recipe behind each Match, so tapping one opens it in full.
    private var recipesByID: [String: Recipe] {
        Dictionary(recipes.map { ($0.id.uuidString, $0) }, uniquingKeysWith: { first, _ in first })
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
        .navigationDestination(for: Recipe.self) { recipe in
            LocalRecipeInfoView(recipe: recipe, allowEdit: true)
        }
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
            search.search(in: recipes.map(MatchableRecipe.init))
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
            message("Add the foods you have on hand and we'll find the recipes on this device you can cook.")

        case .noMatches:
            message("None of your recipes use what you have. Try adding another food, or save a few more recipes.")

        case .matches(let matches):
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(matches, id: \.recipeID) { match in
                        // A Match the store cannot name is still a Match, so it
                        // is shown; it just has no Recipe to open.
                        if let recipe = recipesByID[match.recipeID] {
                            NavigationLink(value: recipe) {
                                PantryMatchRow(match: match)
                            }
                            .buttonStyle(.plain)
                        } else {
                            PantryMatchRow(match: match)
                        }
                    }
                }
                .padding(.horizontal)
            }
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
