import SwiftUI

struct MealPlanDayView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var mealPlanDay: MealPlanDay
    @State private var pendingRemoval: PlannedRecipe?
    @State private var selectedRecipe: Recipe?
    @State private var selectedMealType: MealType?

    /// A Recipe under the Meal Type it is planned for: removing it needs both, and an alert
    /// driven by one shared flag would ask about whichever row happened to render first.
    struct PlannedRecipe: Identifiable {
        let recipe: Recipe
        let mealType: MealType

        var id: String { "\(mealType.rawValue)-\(recipe.id)" }
    }

    private var isRemoving: Binding<Bool> {
        Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            ForEach(MealType.allCases, id: \.self) { type in
                VStack(alignment: .leading, spacing: Spacing.m) {
                    SectionHeader(type.rawValue) {
                        Button {
                            selectedMealType = type
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add a \(type.rawValue.lowercased())")
                    }

                    if mealPlanDay[type].isEmpty {
                        Text("You don't have any meals planned for \(type.rawValue)")
                            .textStyle(.body)
                            .foregroundStyle(Color.contentSecondary)
                    } else {
                        ForEach(mealPlanDay[type]) { recipe in
                            ListRowCard(
                                title: recipe.name,
                                removeLabel: "Remove \(recipe.name)"
                            ) {
                                selectedRecipe = recipe
                            } onRemove: {
                                pendingRemoval = PlannedRecipe(recipe: recipe, mealType: type)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .confirmationDialog(
            "Remove this recipe from the day?",
            isPresented: isRemoving,
            titleVisibility: .visible,
            presenting: pendingRemoval
        ) { planned in
            Button("Remove", role: .destructive) {
                removeRecipeFromCalendar(planned.recipe, planned.mealType)
            }
            Button("Keep", role: .cancel) {}
        } message: { planned in
            Text("\(planned.recipe.name) comes off \(planned.mealType.rawValue.lowercased()).")
        }
        .sheet(item: $selectedMealType) { mealType in
            AddToMealPlanDaySheet(mealType: mealType, addRecipeToCalendar: addRecipeToCalendar)
        }
        .navigationDestination(item: $selectedRecipe) { recipe in
            LocalRecipeInfoView(recipe: recipe, allowEdit: true)
        }
    }

    func addRecipeToCalendar(_ recipe: Recipe, _ mealType: MealType) {
        mealPlanDay[mealType].append(recipe)
    }

    func removeRecipeFromCalendar(_ recipe: Recipe, _ mealType: MealType) {
        if let idx = mealPlanDay[mealType].firstIndex(where: { $0.id == recipe.id }) {
            mealPlanDay[mealType].remove(at: idx)
        }
    }
}

#Preview {
    let mealPlanDay = MealPlanDay(dayKey: Date().dayKey)
    NavigationStack {
        ScrollView {
            MealPlanDayView(mealPlanDay: mealPlanDay)
                .padding(.horizontal, Spacing.xl)
        }
        .background(Color.surface)
    }
}
