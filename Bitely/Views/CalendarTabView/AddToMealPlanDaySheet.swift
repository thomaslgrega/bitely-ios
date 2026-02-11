//
//  AddToMealPlanDaySheet.swift
//  Bitely
//
//  Created by Thomas Grega on 12/17/25.
//

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
            List {
                if recipes.isEmpty {
                    Text("Save or create recipes to add to your calendar.")
                        .foregroundStyle(Color.secondary400)
                        .italic()
                } else {
                    ForEach(recipes) { recipe in
                        HStack {
                            Image(systemName: selectedRecipes.contains(recipe) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedRecipes.contains(recipe) ? Color.primaryMain : Color.secondaryMain)

                            Text(recipe.name)
                        }
                        .onTapGesture {
                            if selectedRecipes.contains(recipe) {
                                selectedRecipes.remove(recipe)
                            } else {
                                selectedRecipes.insert(recipe)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .principal) {
                    Text("Add a \(mealType.rawValue.lowercased())")
                        .foregroundStyle(Color.secondary700)
                        .bold()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        for recipe in selectedRecipes {
                            addRecipeToCalendar(recipe, mealType)
                        }

                        dismiss()
                    }
                    .disabled(selectedRecipes.isEmpty)
                }
            }
            .toolbarBackground(Color.secondary100, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    AddToMealPlanDaySheet(mealType: .breakfast, addRecipeToCalendar: { _, _ in } )
}
