//
//  Mock data and shared pieces for the RecipesTabView redesign.
//
//  Nothing here touches SwiftData, the network or the real stores, so the
//  redesign runs in a preview with no environment set up.
//

import SwiftUI

// MARK: - Palette

/// The inspiration board's three brand colors, plus the tints the cards use.
enum Redesign {
    static let cream = Color(hex: "#FFFBF7")
    static let red = Color(hex: "#932D2C")
    static let ink = Color(hex: "#24211D")
    static let inkSoft = Color(hex: "#6B655C")
    static let hairline = Color(hex: "#E8E0D6")

    /// Headings are Fraunces, bundled in Resources/Fonts under the SIL OFL and
    /// registered in Info.plist; body copy stays the system sans.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(weight == .regular ? "Fraunces-Regular" : "Fraunces-SemiBold", size: size)
    }

    static func tint(for category: FoodCategory) -> Color {
        switch category {
        case .beef: Color(hex: "#E9C8C0")
        case .chicken: Color(hex: "#F0DCC0")
        case .dessert: Color(hex: "#EBD3DA")
        case .other: Color(hex: "#DDD8CE")
        case .pasta: Color(hex: "#F2E1BC")
        case .pork: Color(hex: "#E7CBC7")
        case .seafood: Color(hex: "#C9DBE2")
        case .side: Color(hex: "#D6DFC8")
        case .vegetarian: Color(hex: "#CDDCC6")
        case .breakfast: Color(hex: "#F1DFC8")
        }
    }
}

// MARK: - Mock model

struct MockRecipe: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: FoodCategory
    let calories: Int?
    let totalCookTime: Int?
    /// The foods this Recipe needs, so the mock pantry search has something to match on.
    let ingredients: [String]

    var cookTimeText: String { totalCookTime.map { "\($0) min" } ?? "—" }
    var caloriesText: String { calories.map { "\($0) cal" } ?? "—" }
}

extension MockRecipe {
    static let all: [MockRecipe] = [
        MockRecipe(name: "Braised Short Rib", category: .beef, calories: 720, totalCookTime: 190,
                   ingredients: ["beef", "onion", "red wine", "carrot"]),
        MockRecipe(name: "Steak au Poivre", category: .beef, calories: 640, totalCookTime: 35,
                   ingredients: ["beef", "butter", "cream", "peppercorn"]),
        MockRecipe(name: "Lemon Roast Chicken", category: .chicken, calories: 480, totalCookTime: 75,
                   ingredients: ["chicken", "lemon", "garlic", "thyme"]),
        MockRecipe(name: "Chicken Katsu Curry", category: .chicken, calories: 810, totalCookTime: 50,
                   ingredients: ["chicken", "egg", "onion", "rice"]),
        MockRecipe(name: "Burnt Basque Cheesecake", category: .dessert, calories: 430, totalCookTime: 65,
                   ingredients: ["cream cheese", "egg", "sugar", "cream"]),
        MockRecipe(name: "Olive Oil Citrus Cake", category: .dessert, calories: 360, totalCookTime: 55,
                   ingredients: ["flour", "orange", "olive oil", "egg"]),
        MockRecipe(name: "Cacio e Pepe", category: .pasta, calories: 590, totalCookTime: 20,
                   ingredients: ["pasta", "pecorino", "peppercorn", "butter"]),
        MockRecipe(name: "Rigatoni alla Vodka", category: .pasta, calories: 660, totalCookTime: 40,
                   ingredients: ["pasta", "tomato", "cream", "onion"]),
        MockRecipe(name: "Maple Pork Belly", category: .pork, calories: 780, totalCookTime: 150,
                   ingredients: ["pork", "maple syrup", "garlic", "soy sauce"]),
        MockRecipe(name: "Miso Butter Scallops", category: .seafood, calories: 340, totalCookTime: 18,
                   ingredients: ["scallops", "butter", "miso", "lemon"]),
        MockRecipe(name: "Charred Lemon Salmon", category: .seafood, calories: 520, totalCookTime: 25,
                   ingredients: ["salmon", "lemon", "olive oil", "dill"]),
        MockRecipe(name: "Smashed Potatoes", category: .side, calories: 290, totalCookTime: 45,
                   ingredients: ["potato", "butter", "rosemary", "garlic"]),
        MockRecipe(name: "Charred Broccolini", category: .side, calories: 160, totalCookTime: 15,
                   ingredients: ["broccolini", "chili", "garlic", "lemon"]),
        MockRecipe(name: "Mushroom Ragù", category: .vegetarian, calories: 450, totalCookTime: 60,
                   ingredients: ["mushroom", "onion", "tomato", "thyme"]),
        MockRecipe(name: "Halloumi Grain Bowl", category: .vegetarian, calories: 520, totalCookTime: 30,
                   ingredients: ["halloumi", "farro", "cucumber", "lemon"]),
        MockRecipe(name: "Brown Butter Pancakes", category: .breakfast, calories: 610, totalCookTime: 25,
                   ingredients: ["flour", "egg", "butter", "milk"]),
        MockRecipe(name: "Shakshuka", category: .breakfast, calories: 380, totalCookTime: 35,
                   ingredients: ["egg", "tomato", "onion", "paprika"]),
        MockRecipe(name: "Grandma's Pot Roast", category: .other, calories: 700, totalCookTime: 210,
                   ingredients: ["beef", "potato", "carrot", "onion"])
    ]

    static func inCategory(_ category: FoodCategory) -> [MockRecipe] {
        all.filter { $0.category == category }
    }

    /// Stands in for the two-source pantry search: everything that shares at least one
    /// food with the pantry, most overlap first.
    static func matching(pantry: [String]) -> [(recipe: MockRecipe, matched: Int)] {
        guard !pantry.isEmpty else { return [] }
        let wanted = Set(pantry.map { $0.lowercased() })
        return all
            .map { ($0, $0.ingredients.filter { wanted.contains($0) }.count) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }
}

// MARK: - Shared presentation state

/// The bookmark set and the pantry draft, standing in for the SwiftData store
/// and the pantry search's state.
@Observable
final class MockRecipeStore {
    var savedIds: Set<UUID> = [MockRecipe.all[2].id, MockRecipe.all[6].id]
    var pantryItems: [String] = []

    func isSaved(_ recipe: MockRecipe) -> Bool { savedIds.contains(recipe.id) }

    func toggleSaved(_ recipe: MockRecipe) {
        if savedIds.contains(recipe.id) {
            savedIds.remove(recipe.id)
        } else {
            savedIds.insert(recipe.id)
        }
    }
}

// MARK: - Shared pieces

/// The stand-in for a Recipe photo: the category icon on its tint, the way the
/// inspiration shoots products on flat color blocks.
struct MockThumbnail: View {
    let category: FoodCategory
    var cornerRadius: CGFloat = 18
    var inset: CGFloat = 0.42

    var body: some View {
        GeometryReader { proxy in
            Redesign.tint(for: category)
                .overlay {
                    Image(category.rawValue.lowercased())
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(proxy.size.width, proxy.size.height) * (1 - inset))
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct SaveButton: View {
    let recipe: MockRecipe
    var store: MockRecipeStore

    var body: some View {
        Button {
            withAnimation(.snappy) { store.toggleSaved(recipe) }
        } label: {
            Image(systemName: store.isSaved(recipe) ? "heart.fill" : "heart")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(store.isSaved(recipe) ? Redesign.red : Redesign.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Redesign.cream))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(store.isSaved(recipe) ? "Remove bookmark" : "Bookmark recipe")
    }
}

struct MetaLabel: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Redesign.inkSoft)
    }
}
