import SwiftData
import SwiftUI

struct AddToMealPlanDaySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\Recipe.name)]) var recipes: [Recipe]
    @State private var selectedRecipes: Set<Recipe> = []

    let mealType: MealType
    let addRecipeToCalendar: (Recipe, MealType) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                contents
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.surface)
            .navigationTitle("Add a \(mealType.rawValue.lowercased())")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(Color.contentPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", action: add)
                        .tint(Color.accent)
                        .disabled(selectedRecipes.isEmpty)
                }
            }
            .toolbarBackground(Color.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var contents: some View {
        if recipes.isEmpty {
            EmptyState(
                systemImage: "book.closed",
                title: "Nothing to plan yet",
                message: "Recipes you write or save from other people can be planned here."
            )
        } else {
            RecipeGrid(items: recipes) { recipe in
                tile(for: recipe)
            }
            .padding(.top, Spacing.l)
        }
    }

    /// A picker tile carries no save heart — design-system.md, RecipeTile — so the only
    /// control on the thumbnail is the one saying whether this Recipe is going on the day.
    private func tile(for recipe: Recipe) -> some View {
        Button {
            toggle(recipe)
        } label: {
            RecipeTile(recipe: RecipeSummary(recipe))
                .overlay(alignment: .topTrailing) {
                    SelectionIndicator(isSelected: selectedRecipes.contains(recipe))
                        .onThumbnail
                        .padding(Spacing.s)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(recipe.name)
        .accessibilityAddTraits(SelectionState(isSelected: selectedRecipes.contains(recipe)).traits)
    }

    private func toggle(_ recipe: Recipe) {
        withAnimation(.snappy) {
            if selectedRecipes.contains(recipe) {
                selectedRecipes.remove(recipe)
            } else {
                selectedRecipes.insert(recipe)
            }
        }
    }

    private func add() {
        for recipe in selectedRecipes {
            addRecipeToCalendar(recipe, mealType)
        }

        dismiss()
    }
}

@MainActor
private func plannableRecipes() -> ModelContainer {
    let container = try! ModelContainer(
        for: Recipe.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    for recipe in [
        Recipe(name: "Slow-Braised Short Rib with Red Wine", category: .beef, calories: 720, totalCookTime: 190),
        Recipe(name: "Shakshuka", category: .breakfast, calories: 410, totalCookTime: 35),
        Recipe(name: "Brown Butter Gnocchi", category: .pasta, calories: 640, totalCookTime: 45)
    ] {
        container.mainContext.insert(recipe)
    }

    return container
}

/// The pair of sizes the grid's collapse exists for: at `.accessibility3` the picker is one
/// column and no recipe name clips — design-system.md, Dynamic Type.
#Preview("Large") {
    AddToMealPlanDaySheet(mealType: .breakfast, addRecipeToCalendar: { _, _ in })
        .modelContainer(plannableRecipes())
        .dynamicTypeSize(.large)
}

#Preview("Accessibility 3") {
    AddToMealPlanDaySheet(mealType: .breakfast, addRecipeToCalendar: { _, _ in })
        .modelContainer(plannableRecipes())
        .dynamicTypeSize(.accessibility3)
}

#Preview("Nothing to plan") {
    AddToMealPlanDaySheet(mealType: .breakfast, addRecipeToCalendar: { _, _ in })
        .modelContainer(for: Recipe.self, inMemory: true)
}
