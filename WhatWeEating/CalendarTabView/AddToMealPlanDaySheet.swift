//
//  AddToMealPlanDaySheet.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/17/25.
//

import SwiftData
import SwiftUI

struct AddToMealPlanDaySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\Recipe.strMeal)]) var recipes: [Recipe]
    @State private var selectedRecipe: Recipe?

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
                            Image(systemName: selectedRecipe == recipe ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedRecipe == recipe ? Color.primaryMain : Color.secondaryMain)

                            Text(recipe.strMeal)
                        }
                        .onTapGesture {
                            selectedRecipe = recipe
                        }
                    }
                }
            }
            .navigationTitle("Add a \(mealType.rawValue.lowercased())")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        if let recipe = selectedRecipe {
                            addRecipeToCalendar(recipe, mealType)
                        }

                        dismiss()
                    }
                    .disabled(selectedRecipe == nil)
                }
            }
        }
    }
}

#Preview {
    AddToMealPlanDaySheet(mealType: .breakfast, addRecipeToCalendar: { _, _ in } )
}
