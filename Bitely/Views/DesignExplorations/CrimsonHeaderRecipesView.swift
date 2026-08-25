//
//  Exploration 2 — Crimson Header.
//
//  A full-bleed red masthead carrying the title and search, with the content
//  riding up over it on a cream sheet. Categories are large two-column tiles,
//  the way the current tab lists them, and the Recipes below are compact rows.
//

import SwiftUI

struct CrimsonHeaderRecipesView: View {
    @State private var store = MockRecipeStore()
    @State private var showSettings = false
    @State private var query = ""

    private var results: [MockRecipe] {
        guard !query.isEmpty else { return Array(MockRecipe.all.prefix(6)) }
        return MockRecipe.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    masthead

                    VStack(alignment: .leading, spacing: 26) {
                        pantryCard
                        categoryTiles
                        recipeRows
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30, style: .continuous)
                            .fill(Redesign.cream)
                    )
                    .offset(y: -26)
                }
            }
            .background(Redesign.red)
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FoodCategory.self) { MockCategoryListView(category: $0, store: store) }
            .navigationDestination(for: MockRecipe.self) { MockRecipeDetailView(recipe: $0, store: store) }
            .sheet(isPresented: $showSettings) { MockSettingsSheet() }
        }
        .tint(Redesign.red)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Bitely")
                    .font(Redesign.serif(22, .semibold))
                    .foregroundStyle(Redesign.cream)
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Redesign.cream)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }

            Text("What are we\neating tonight?")
                .font(Redesign.serif(34, .semibold))
                .foregroundStyle(Redesign.cream)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Redesign.inkSoft)
                TextField("Search recipes", text: $query)
                    .autocorrectionDisabled()
                    .foregroundStyle(Redesign.ink)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Redesign.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Capsule().fill(Redesign.cream))
            .padding(.bottom, 34)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var pantryCard: some View {
        NavigationLink {
            MockPantrySearchView(store: store)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "basket.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Redesign.cream)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Redesign.red))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Cook what you have")
                        .font(Redesign.serif(20, .semibold))
                        .foregroundStyle(Redesign.ink)
                    Text("Match the foods on hand against your recipes and shared ones")
                        .font(.system(size: 13))
                        .foregroundStyle(Redesign.inkSoft)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Redesign.ink)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Redesign.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var categoryTiles: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Categories")
                .font(Redesign.serif(24, .semibold))
                .foregroundStyle(Redesign.ink)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(FoodCategory.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(category.rawValue.lowercased())
                                .resizable()
                                .scaledToFit()
                                .frame(height: 44)

                            Text(category.rawValue)
                                .font(Redesign.serif(18, .semibold))
                                .foregroundStyle(Redesign.ink)

                            Text("^[\(MockRecipe.inCategory(category).count) recipe](inflect: true)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Redesign.inkSoft)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Redesign.tint(for: category).opacity(0.55))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recipeRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(query.isEmpty ? "Fresh from the community" : "\(results.count) matches")
                .font(Redesign.serif(24, .semibold))
                .foregroundStyle(Redesign.ink)

            ForEach(results) { recipe in
                NavigationLink(value: recipe) {
                    HStack(spacing: 14) {
                        MockThumbnail(category: recipe.category, cornerRadius: 16)
                            .frame(width: 74, height: 74)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(recipe.name)
                                .font(Redesign.serif(18, .semibold))
                                .foregroundStyle(Redesign.ink)
                                .multilineTextAlignment(.leading)

                            HStack(spacing: 12) {
                                MetaLabel(systemImage: "clock", text: recipe.cookTimeText)
                                MetaLabel(systemImage: "flame", text: recipe.caloriesText)
                            }
                        }

                        Spacer(minLength: 0)
                        SaveButton(recipe: recipe, store: store)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Redesign.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    CrimsonHeaderRecipesView()
}
