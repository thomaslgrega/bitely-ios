//
//  AddRecipeView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/1/25.
//

import SwiftUI

struct AddRecipeView: View {
    @FocusState private var isKeyboardActive: Bool
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var recipe: Recipe

    var body: some View {
        Form {
            Section("Recipe Name") {
                TextField("Recipe Name", text: $recipe.strMeal)
                    .focused($isKeyboardActive)
            }

            Section("Ingredients") {
                ForEach($recipe.ingredients) { $ingredient in
                    IngredientRowView(ingredient: $ingredient, onDelete: {
                        removeIngredient(ingredient)
                    })
                }
                .focused($isKeyboardActive)

                if recipe.ingredients.count < 20 {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.blue)
                        Button("Add an ingredient", action: addNewIngredient)
                    }
                }
            }

            Section("Instructions") {
                TextField("Instructions", text: $recipe.strInstructions.orEmpty(), axis: .vertical)
                    .focused($isKeyboardActive)
            }
        }
        .navigationTitle("Add a New Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                saveRecipe()
            } label: {
                Text("Save")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isKeyboardActive = false
                }
            }
        }
    }

    func addNewIngredient() {
        recipe.ingredients.append(Ingredient(name: "", measurementRaw: "", isParsed: true))
    }

    func removeIngredient(_ ingredient: Ingredient) {
        if let idx = recipe.ingredients.firstIndex(where: { $0.id == ingredient.id }) {
            recipe.ingredients.remove(at: idx)
        }
    }

    func saveRecipe() {
        for ingredient in recipe.ingredients {
            if ingredient.isParsed {
                if let qty = ingredient.measurementQty {
                    ingredient.measurementRaw = "\(qty.trimTrailingZeros()) \(ingredient.measurementUnit?.displayName ?? "")"
                }
            }
        }
        
        modelContext.insert(recipe)
        dismiss()
    }
}

#Preview {
    let ingredient1 = Ingredient(name: "Tomato", measurementRaw: "2")
    let ingredient2 = Ingredient(name: "Sugar", measurementRaw: "200g", measurementQty: 3, measurementUnit: MeasurementUnit.gram, isParsed: true)

    NavigationStack {
        AddRecipeView(recipe: Recipe(id: "", strMeal: "", strMealThumb: "", ingredients: [ingredient1, ingredient2]))
    }
}
