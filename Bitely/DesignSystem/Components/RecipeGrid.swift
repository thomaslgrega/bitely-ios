import SwiftUI

/// How many columns a recipe grid gets. `GridItem(.adaptive(minimum:))` does not answer
/// this — it responds to container width, which does not change when text grows.
enum RecipeGridLayout {
    static func columnCount(for size: DynamicTypeSize) -> Int {
        size.isAccessibilitySize ? 1 : 2
    }
}

/// The two-column grid of `RecipeTile`s, collapsing to one column at the accessibility sizes.
struct RecipeGrid<Item: Identifiable, Tile: View>: View {
    let items: [Item]
    var rowSpacing: CGFloat = Spacing.xl
    var columnSpacing: CGFloat = 14
    @ViewBuilder let tile: (Item) -> Tile

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: columnSpacing),
            count: RecipeGridLayout.columnCount(for: dynamicTypeSize)
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: rowSpacing) {
            ForEach(items) { tile($0) }
        }
    }
}

#Preview("Accessibility 3 collapses to one column") {
    ScrollView {
        RecipeGrid(items: FoodCategory.allCases.map { IdentifiedCategory(category: $0) }) { item in
            RecipeTile(
                name: "Slow-Braised \(item.category.rawValue)",
                thumbnail: .categoryTint(item.category),
                cookTime: 45,
                calories: 520
            )
        }
        .padding()
    }
    .background(Color.surface)
    .dynamicTypeSize(.accessibility3)
}

private struct IdentifiedCategory: Identifiable {
    let category: FoodCategory
    var id: FoodCategory { category }
}
