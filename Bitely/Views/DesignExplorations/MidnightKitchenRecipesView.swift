//
//  Exploration 3 — Midnight Kitchen.
//
//  The dark half of the palette carries the whole screen: ink background, cream
//  type, and one full-bleed Recipe per card. Categories ride as a pill rail that
//  filters the feed in place, and the pantry search is the first card in it.
//

import SwiftUI

struct MidnightKitchenRecipesView: View {
    @State private var store = MockRecipeStore()
    @State private var showSettings = false
    @State private var selectedCategory: FoodCategory?

    private var feed: [MockRecipe] {
        guard let selectedCategory else { return MockRecipe.all }
        return MockRecipe.inCategory(selectedCategory)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    pantryBanner
                    categoryRail
                    feedCards
                }
                .padding(.bottom, 32)
            }
            .background(Redesign.ink)
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FoodCategory.self) { MockCategoryListView(category: $0, store: store) }
            .navigationDestination(for: MockRecipe.self) { MockRecipeDetailView(recipe: $0, store: store) }
            .sheet(isPresented: $showSettings) { MockSettingsSheet() }
            .preferredColorScheme(.dark)
        }
        .tint(Redesign.cream)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tonight")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Redesign.cream.opacity(0.5))
                    .textCase(.uppercase)
                    .kerning(1.4)
                Text("Find a recipe")
                    .font(Redesign.serif(34, .semibold))
                    .foregroundStyle(Redesign.cream)
            }

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Redesign.cream)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var pantryBanner: some View {
        NavigationLink {
            MockPantrySearchView(store: store)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "basket.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Redesign.cream)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Redesign.red))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Cook what you have")
                        .font(Redesign.serif(19, .semibold))
                        .foregroundStyle(Redesign.cream)
                    Text(store.pantryItems.isEmpty
                         ? "Search by the foods on hand"
                         : store.pantryItems.joined(separator: ", "))
                        .font(.system(size: 13))
                        .foregroundStyle(Redesign.cream.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Redesign.cream.opacity(0.7))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }

    private var categoryRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                pill(title: "All", isSelected: selectedCategory == nil) {
                    withAnimation(.snappy) { selectedCategory = nil }
                }

                ForEach(FoodCategory.allCases, id: \.self) { category in
                    pill(title: category.rawValue, isSelected: selectedCategory == category) {
                        withAnimation(.snappy) { selectedCategory = category }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func pill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Redesign.ink : Redesign.cream.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(isSelected ? Redesign.cream : Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    private var feedCards: some View {
        LazyVStack(spacing: 18) {
            ForEach(feed) { recipe in
                NavigationLink(value: recipe) {
                    ZStack(alignment: .bottom) {
                        MockThumbnail(category: recipe.category, cornerRadius: 28, inset: 0.6)
                            .frame(height: 240)

                        LinearGradient(
                            colors: [.clear, Redesign.ink.opacity(0.85)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(recipe.category.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .kerning(1.2)
                                    .foregroundStyle(Redesign.cream.opacity(0.7))

                                Text(recipe.name)
                                    .font(Redesign.serif(24, .semibold))
                                    .foregroundStyle(Redesign.cream)
                                    .multilineTextAlignment(.leading)

                                HStack(spacing: 14) {
                                    MetaLabel(systemImage: "clock", text: recipe.cookTimeText, color: Redesign.cream.opacity(0.75))
                                    MetaLabel(systemImage: "flame", text: recipe.caloriesText, color: Redesign.cream.opacity(0.75))
                                }
                            }

                            Spacer(minLength: 0)
                            SaveButton(recipe: recipe, store: store, style: .dark)
                        }
                        .padding(18)
                    }
                    .frame(height: 240)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    MidnightKitchenRecipesView()
}
