//
//  Editorial Feed — the chosen direction for the RecipesTabView redesign.
//
//  The inspiration's home screen almost verbatim: a greeting bar, one dark
//  promo card that carries the pantry search, category chips that filter the
//  grid in place, and a two-column grid with a save control on each image.
//
//  Still mock data. docs/design/recipes-redesign-handoff.md holds the questions
//  that wiring this to the real services has to answer first.
//

import SwiftUI

struct EditorialFeedRecipesView: View {
    @State private var store = MockRecipeStore()
    @State private var showSettings = false
    @State private var selectedCategory: FoodCategory?

    private var visibleRecipes: [MockRecipe] {
        guard let selectedCategory else { return MockRecipe.all }
        return MockRecipe.inCategory(selectedCategory)
    }

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greeting
                    pantryPromo
                    categoryChips
                    grid
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Redesign.cream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FoodCategory.self) { MockCategoryListView(category: $0, store: store) }
            .navigationDestination(for: MockRecipe.self) { MockRecipeDetailView(recipe: $0, store: store) }
            .sheet(isPresented: $showSettings) { MockSettingsSheet() }
        }
        .tint(Redesign.red)
    }

    private var greeting: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Redesign.tint(for: .breakfast))
                .frame(width: 46, height: 46)
                .overlay(Text("N").font(Redesign.serif(20, .semibold)).foregroundStyle(Redesign.ink))

            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome,")
                Text("Nicky M.")
            }
            .font(Redesign.serif(19, .semibold))
            .foregroundStyle(Redesign.ink)

            Spacer()

            NavigationLink {
                MockPantrySearchView(store: store)
            } label: {
                circleButton("magnifyingglass")
            }
            .buttonStyle(.plain)

            Button { showSettings = true } label: { circleButton("gearshape") }
                .buttonStyle(.plain)
        }
        .padding(.top, 12)
    }

    private func circleButton(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Redesign.ink)
            .frame(width: 46, height: 46)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Redesign.hairline, lineWidth: 1))
    }

    private var pantryPromo: some View {
        NavigationLink {
            MockPantrySearchView(store: store)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Image("vegetarian")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .offset(x: 30, y: 30)
                    .opacity(0.9)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Cook what\nyou have")
                        .font(Redesign.serif(30, .semibold))
                        .foregroundStyle(Redesign.cream)

                    Text("Search your recipes and shared\nones by the foods on hand")
                        .font(.system(size: 13))
                        .foregroundStyle(Redesign.cream.opacity(0.7))

                    Text("Start searching")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Redesign.ink)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Redesign.cream))
                        .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
            }
            .background(Redesign.ink)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var categoryChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Browse by category")
                    .font(Redesign.serif(24, .semibold))
                    .foregroundStyle(Redesign.ink)
                Spacer()
                if selectedCategory != nil {
                    Button("Clear") { withAnimation(.snappy) { selectedCategory = nil } }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Redesign.red)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FoodCategory.allCases, id: \.self) { category in
                        let isSelected = selectedCategory == category
                        Button {
                            withAnimation(.snappy) { selectedCategory = isSelected ? nil : category }
                        } label: {
                            HStack(spacing: 8) {
                                Image(category.rawValue.lowercased())
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                Text(category.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(isSelected ? Redesign.cream : Redesign.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(isSelected ? Redesign.red : .white))
                            .overlay(Capsule().stroke(Redesign.hairline, lineWidth: isSelected ? 0 : 1))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            NavigationLink("Open \(category.rawValue)", value: category)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    private var grid: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(selectedCategory?.rawValue ?? "Popular now")
                    .font(Redesign.serif(24, .semibold))
                    .foregroundStyle(Redesign.ink)
                Spacer()
                if let selectedCategory {
                    NavigationLink(value: selectedCategory) {
                        HStack(spacing: 4) {
                            Text("View all")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Redesign.red)
                    }
                }
            }

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(visibleRecipes) { recipe in
                    NavigationLink(value: recipe) {
                        VStack(alignment: .leading, spacing: 8) {
                            MockThumbnail(category: recipe.category)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(alignment: .topTrailing) {
                                    MockSaveButton(recipe: recipe, store: store).padding(8)
                                }

                            Text(recipe.name)
                                .font(Redesign.serif(16, .semibold))
                                .foregroundStyle(Redesign.ink)
                                .lineLimit(2, reservesSpace: true)
                                .multilineTextAlignment(.leading)

                            HStack(spacing: 10) {
                                MockMetaLabel(systemImage: "clock", text: recipe.cookTimeText)
                                MockMetaLabel(systemImage: "flame", text: recipe.caloriesText)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    EditorialFeedRecipesView()
}
