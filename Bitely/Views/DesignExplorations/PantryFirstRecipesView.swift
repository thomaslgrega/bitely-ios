//
//  Exploration 5 — Pantry First.
//
//  The pantry search is not a card leading elsewhere; it is the top of the tab.
//  Foods entered here filter the mosaic below in place, with the category ring
//  narrowing it further, so browsing and matching are the same gesture.
//

import SwiftUI

struct PantryFirstRecipesView: View {
    @State private var store = MockRecipeStore()
    @State private var showSettings = false
    @State private var draft = ""
    @State private var selectedCategory: FoodCategory?
    @FocusState private var draftFocused: Bool

    /// Pantry first, then the category ring: whichever filters are set apply together.
    private var results: [MockRecipe] {
        let base = store.pantryItems.isEmpty
            ? MockRecipe.all
            : MockRecipe.matching(pantry: store.pantryItems).map(\.recipe)

        guard let selectedCategory else { return base }
        return base.filter { $0.category == selectedCategory }
    }

    private var leftColumn: [MockRecipe] { results.enumerated().filter { $0.offset.isMultiple(of: 2) }.map(\.element) }
    private var rightColumn: [MockRecipe] { results.enumerated().filter { !$0.offset.isMultiple(of: 2) }.map(\.element) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    pantryField
                    if !store.pantryItems.isEmpty { pantryChips }
                    categoryRing
                    resultsHeading
                    mosaic
                }
                .padding(.bottom, 36)
            }
            .background(Redesign.cream)
            .scrollDismissesKeyboard(.immediately)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FoodCategory.self) { MockCategoryListView(category: $0, store: store) }
            .navigationDestination(for: MockRecipe.self) { MockRecipeDetailView(recipe: $0, store: store) }
            .sheet(isPresented: $showSettings) { MockSettingsSheet() }
        }
        .tint(Redesign.red)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("What's in\nyour kitchen?")
                .font(Redesign.serif(32, .semibold))
                .foregroundStyle(Redesign.ink)

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Redesign.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.white))
                    .overlay(Circle().stroke(Redesign.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var pantryField: some View {
        HStack(spacing: 10) {
            Image(systemName: "basket")
                .foregroundStyle(Redesign.red)

            TextField("Add a food you have, e.g. eggs", text: $draft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($draftFocused)
                .onSubmit(addDraft)
                .foregroundStyle(Redesign.ink)

            Button(action: addDraft) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Redesign.cream)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Redesign.ink))
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.leading, 18)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(Capsule().fill(.white))
        .overlay(Capsule().stroke(Redesign.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    private var pantryChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            FlowRow(spacing: 8) {
                ForEach(store.pantryItems, id: \.self) { item in
                    HStack(spacing: 6) {
                        Text(item)
                        Button {
                            withAnimation(.snappy) { store.pantryItems.removeAll { $0 == item } }
                        } label: {
                            Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Redesign.cream)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Redesign.red))
                }
            }

            NavigationLink {
                MockPantrySearchView(store: store)
            } label: {
                HStack(spacing: 6) {
                    Text("Open the full pantry search")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Redesign.red)
            }
        }
        .padding(.horizontal, 20)
    }

    private var categoryRing: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(FoodCategory.allCases, id: \.self) { category in
                    let isSelected = selectedCategory == category
                    Button {
                        withAnimation(.snappy) { selectedCategory = isSelected ? nil : category }
                    } label: {
                        VStack(spacing: 8) {
                            Image(category.rawValue.lowercased())
                                .resizable()
                                .scaledToFit()
                                .frame(width: 34, height: 34)
                                .frame(width: 66, height: 66)
                                .background(Circle().fill(Redesign.tint(for: category).opacity(isSelected ? 1 : 0.5)))
                                .overlay(Circle().stroke(Redesign.ink, lineWidth: isSelected ? 2 : 0))

                            Text(category.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(Redesign.ink)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        NavigationLink("Open \(category.rawValue)", value: category)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var resultsHeading: some View {
        HStack {
            Text(store.pantryItems.isEmpty ? "All recipes" : "You can cook \(results.count)")
                .font(Redesign.serif(24, .semibold))
                .foregroundStyle(Redesign.ink)

            Spacer()

            if selectedCategory != nil || !store.pantryItems.isEmpty {
                Button("Reset") {
                    withAnimation(.snappy) {
                        selectedCategory = nil
                        store.pantryItems.removeAll()
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Redesign.red)
            }
        }
        .padding(.horizontal, 20)
    }

    private var mosaic: some View {
        HStack(alignment: .top, spacing: 14) {
            mosaicColumn(leftColumn, firstIsTall: true)
            mosaicColumn(rightColumn, firstIsTall: false)
        }
        .padding(.horizontal, 20)
    }

    private func mosaicColumn(_ recipes: [MockRecipe], firstIsTall: Bool) -> some View {
        LazyVStack(spacing: 14) {
            ForEach(Array(recipes.enumerated()), id: \.element.id) { index, recipe in
                let isTall = index.isMultiple(of: 2) == firstIsTall
                NavigationLink(value: recipe) {
                    VStack(alignment: .leading, spacing: 0) {
                        MockThumbnail(category: recipe.category, cornerRadius: 0)
                            .frame(height: isTall ? 190 : 130)
                            .overlay(alignment: .topTrailing) {
                                SaveButton(recipe: recipe, store: store).padding(8)
                            }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(recipe.name)
                                .font(Redesign.serif(16, .semibold))
                                .foregroundStyle(Redesign.ink)
                                .multilineTextAlignment(.leading)

                            HStack(spacing: 10) {
                                MetaLabel(systemImage: "clock", text: recipe.cookTimeText)
                                MetaLabel(systemImage: "flame", text: recipe.caloriesText)
                            }
                        }
                        .padding(12)
                    }
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Redesign.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
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

#Preview {
    PantryFirstRecipesView()
}
