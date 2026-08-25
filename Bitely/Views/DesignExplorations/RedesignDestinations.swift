//
//  The screens every exploration pushes to: a category's Recipes, the pantry
//  search, a Recipe, and settings. They are shared so the five explorations
//  differ in the tab itself rather than in what sits behind it.
//

import SwiftUI

struct MockCategoryListView: View {
    let category: FoodCategory
    var store: MockRecipeStore

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(MockRecipe.inCategory(category)) { recipe in
                    NavigationLink(value: recipe) {
                        MockRecipeCard(recipe: recipe, store: store)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Redesign.cream)
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
    }
}

/// The card the shared destinations use; the explorations each draw their own.
struct MockRecipeCard: View {
    let recipe: MockRecipe
    var store: MockRecipeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MockThumbnail(category: recipe.category)
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    SaveButton(recipe: recipe, store: store).padding(8)
                }

            Text(recipe.name)
                .font(Redesign.serif(17, .semibold))
                .foregroundStyle(Redesign.ink)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            HStack(spacing: 12) {
                MetaLabel(systemImage: "clock", text: recipe.cookTimeText)
                MetaLabel(systemImage: "flame", text: recipe.caloriesText)
            }
        }
    }
}

struct MockPantrySearchView: View {
    var store: MockRecipeStore

    @State private var draft = ""
    @State private var hasSearched = false
    @FocusState private var draftFocused: Bool

    private var results: [(recipe: MockRecipe, matched: Int)] {
        MockRecipe.matching(pantry: store.pantryItems)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    TextField("Add a food you have, e.g. eggs", text: $draft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($draftFocused)
                        .onSubmit(addDraft)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(.white))
                        .overlay(Capsule().stroke(Redesign.hairline, lineWidth: 1))

                    Button(action: addDraft) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Redesign.cream)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Redesign.ink))
                    }
                    .buttonStyle(.plain)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if !store.pantryItems.isEmpty {
                    pantryChips

                    Button {
                        withAnimation(.snappy) { hasSearched = true }
                        draftFocused = false
                    } label: {
                        Text("Find recipes")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Redesign.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Redesign.red))
                    }
                    .buttonStyle(.plain)
                }

                if hasSearched {
                    resultsSection
                } else {
                    Text("Add the foods on hand, then search. Your saved recipes are matched on the device; shared recipes come from the corpus.")
                        .font(.system(size: 14))
                        .foregroundStyle(Redesign.inkSoft)
                }
            }
            .padding(20)
        }
        .background(Redesign.cream)
        .navigationTitle("Cook what you have")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pantryChips: some View {
        FlowRow(spacing: 8) {
            ForEach(store.pantryItems, id: \.self) { item in
                HStack(spacing: 6) {
                    Text(item)
                    Button {
                        withAnimation(.snappy) { store.pantryItems.removeAll { $0 == item } }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Redesign.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Redesign.tint(for: .pasta).opacity(0.6)))
            }
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if results.isEmpty {
            Text("Nothing matched those foods.")
                .font(Redesign.serif(20, .semibold))
                .foregroundStyle(Redesign.ink)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                Text("\(results.count) recipes you could cook")
                    .font(Redesign.serif(22, .semibold))
                    .foregroundStyle(Redesign.ink)

                ForEach(results, id: \.recipe.id) { result in
                    NavigationLink(value: result.recipe) {
                        HStack(spacing: 14) {
                            MockThumbnail(category: result.recipe.category, cornerRadius: 14)
                                .frame(width: 66, height: 66)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.recipe.name)
                                    .font(Redesign.serif(17, .semibold))
                                    .foregroundStyle(Redesign.ink)
                                Text("\(result.matched) of \(result.recipe.ingredients.count) ingredients on hand")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Redesign.inkSoft)
                            }

                            Spacer()
                            SaveButton(recipe: result.recipe, store: store)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func addDraft() {
        let item = draft.trimmingCharacters(in: .whitespaces).lowercased()
        guard !item.isEmpty, !store.pantryItems.contains(item) else { return }
        withAnimation(.snappy) { store.pantryItems.append(item) }
        draft = ""
    }
}

struct MockRecipeDetailView: View {
    let recipe: MockRecipe
    var store: MockRecipeStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                MockThumbnail(category: recipe.category, cornerRadius: 26, inset: 0.55)
                    .frame(height: 260)

                Text(recipe.name)
                    .font(Redesign.serif(32, .semibold))
                    .foregroundStyle(Redesign.ink)

                HStack(spacing: 16) {
                    MetaLabel(systemImage: "clock", text: recipe.cookTimeText)
                    MetaLabel(systemImage: "flame", text: recipe.caloriesText)
                    MetaLabel(systemImage: "tag", text: recipe.category.rawValue)
                }

                Text("Ingredients")
                    .font(Redesign.serif(22, .semibold))
                    .foregroundStyle(Redesign.ink)

                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    HStack(spacing: 10) {
                        Circle().fill(Redesign.red).frame(width: 5, height: 5)
                        Text(ingredient.capitalized)
                            .font(.system(size: 16))
                            .foregroundStyle(Redesign.ink)
                    }
                }

                Button {
                    withAnimation(.snappy) { store.toggleSaved(recipe) }
                } label: {
                    Text(store.isSaved(recipe) ? "Saved" : "Save recipe")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Redesign.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(store.isSaved(recipe) ? Redesign.inkSoft : Redesign.ink))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Redesign.cream)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MockSettingsSheet: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Label("Signed in as nicky@example.com", systemImage: "person.crop.circle")
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                Section("App") {
                    Label("Notifications", systemImage: "bell")
                    Label("About Bitely", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

/// A wrapping row, so chips and filters flow onto a second line.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
