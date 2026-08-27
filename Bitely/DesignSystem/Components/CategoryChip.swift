import SwiftUI

/// Chips filter; they never navigate — design-system.md, CategoryChip and ChipRail.
struct CategoryChip: View {
    let category: FoodCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                Image(category.rawValue.lowercased())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text(category.rawValue)
                    .textStyle(.label)
            }
            .chipFace(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(SelectionState(isSelected: isSelected).traits)
    }
}

extension View {
    /// The capsule every chip wears: category chips on Discover, Pantry Items on Pantry
    /// Search — design-system.md, CategoryChip and ChipRail.
    func chipFace(isSelected: Bool = false) -> some View {
        foregroundStyle(isSelected ? Color.contentOnInverse : Color.contentPrimary)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background(Capsule().fill(isSelected ? Color.accent : Color.surfaceRaised))
            .overlay(Capsule().strokeBorder(Color.border, lineWidth: isSelected ? 0 : 1))
    }
}

/// The horizontally scrolling rail of chips. It bleeds past the page margin, so it takes
/// that margin rather than inheriting the page's: the row has to start flush with the text
/// above it and still run to the screen edge.
struct ChipRail: View {
    let categories: [FoodCategory]
    @Binding var selection: FoodCategory?
    var pageMargin: CGFloat = Spacing.xl

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(category: category, isSelected: selection == category) {
                        withAnimation(.snappy) {
                            selection = selection == category ? nil : category
                        }
                    }
                }
            }
            .padding(.horizontal, pageMargin)
        }
        .padding(.horizontal, -pageMargin)
    }
}

private struct ChipRailPreview: View {
    @State private var selection: FoodCategory? = .pasta

    var body: some View {
        ChipRail(categories: FoodCategory.allCases, selection: $selection)
            .padding(.vertical)
            .background(Color.surface)
    }
}

#Preview { ChipRailPreview() }
