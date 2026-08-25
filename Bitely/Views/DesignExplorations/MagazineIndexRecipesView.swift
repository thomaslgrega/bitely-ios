//
//  Exploration 4 — Magazine Index.
//
//  Type first, chrome last: an oversized serif masthead, hairline-ruled rows
//  numbered like a contents page, and a category index that reads as a list
//  rather than a set of tiles. The pantry search is the outlined lead item.
//

import SwiftUI

struct MagazineIndexRecipesView: View {
    @State private var store = MockRecipeStore()
    @State private var showSettings = false
    @State private var selectedCategory: FoodCategory?

    private var entries: [MockRecipe] {
        guard let selectedCategory else { return MockRecipe.all }
        return MockRecipe.inCategory(selectedCategory)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    masthead
                    pantryLead
                    categoryIndex
                    contents
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Redesign.cream)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FoodCategory.self) { MockCategoryListView(category: $0, store: store) }
            .navigationDestination(for: MockRecipe.self) { MockRecipeDetailView(recipe: $0, store: store) }
            .sheet(isPresented: $showSettings) { MockSettingsSheet() }
        }
        .tint(Redesign.red)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ISSUE No. 12 — AUGUST")
                    .font(.system(size: 11, weight: .bold))
                    .kerning(1.6)
                    .foregroundStyle(Redesign.red)
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Redesign.ink)
                }
                .buttonStyle(.plain)
            }

            Text("Find a\nrecipe")
                .font(Redesign.serif(46, .semibold))
                .foregroundStyle(Redesign.ink)
                .lineSpacing(-6)

            Rectangle()
                .fill(Redesign.ink)
                .frame(height: 2)
        }
        .padding(.top, 14)
    }

    private var pantryLead: some View {
        NavigationLink {
            MockPantrySearchView(store: store)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("THE PANTRY")
                    .font(.system(size: 11, weight: .bold))
                    .kerning(1.6)
                    .foregroundStyle(Redesign.red)

                Text("Cook what you have")
                    .font(Redesign.serif(28, .semibold))
                    .foregroundStyle(Redesign.ink)

                Text("Name the foods on hand and we'll match them against your recipes and the shared ones.")
                    .font(.system(size: 14))
                    .foregroundStyle(Redesign.inkSoft)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Text("Start searching")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Redesign.ink)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Redesign.ink, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var categoryIndex: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Index")

            FlowRow(spacing: 10) {
                ForEach(FoodCategory.allCases, id: \.self) { category in
                    let isSelected = selectedCategory == category
                    Button {
                        withAnimation(.snappy) { selectedCategory = isSelected ? nil : category }
                    } label: {
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isSelected ? Redesign.cream : Redesign.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isSelected ? Redesign.ink : .clear)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Redesign.ink.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selectedCategory {
                NavigationLink(value: selectedCategory) {
                    HStack(spacing: 6) {
                        Text("Open the full \(selectedCategory.rawValue) list")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Redesign.red)
                }
            }
        }
    }

    private var contents: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeading(selectedCategory?.rawValue ?? "Contents")
                .padding(.bottom, 8)

            ForEach(Array(entries.enumerated()), id: \.element.id) { index, recipe in
                NavigationLink(value: recipe) {
                    HStack(alignment: .top, spacing: 16) {
                        Text(String(format: "%02d", index + 1))
                            .font(Redesign.serif(15, .semibold))
                            .foregroundStyle(Redesign.red)
                            .frame(width: 26, alignment: .leading)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(recipe.name)
                                .font(Redesign.serif(21, .semibold))
                                .foregroundStyle(Redesign.ink)
                                .multilineTextAlignment(.leading)

                            HStack(spacing: 12) {
                                MetaLabel(systemImage: "tag", text: recipe.category.rawValue)
                                MetaLabel(systemImage: "clock", text: recipe.cookTimeText)
                                MetaLabel(systemImage: "flame", text: recipe.caloriesText)
                            }
                        }

                        Spacer(minLength: 0)

                        MockThumbnail(category: recipe.category, cornerRadius: 6)
                            .frame(width: 62, height: 62)
                            .overlay(alignment: .bottomTrailing) {
                                SaveButton(recipe: recipe, store: store)
                                    .background(Circle().stroke(Redesign.hairline, lineWidth: 1))
                                    .scaleEffect(0.82)
                                    .offset(x: 10, y: 8)
                            }
                    }
                    .padding(.vertical, 16)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Redesign.hairline)
                    .frame(height: 1)
            }
        }
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .bold))
            .kerning(1.8)
            .foregroundStyle(Redesign.inkSoft)
    }
}

#Preview {
    MagazineIndexRecipesView()
}
