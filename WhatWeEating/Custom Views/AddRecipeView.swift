//
//  AddRecipeView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/1/25.
//

import SwiftUI

struct AddRecipeView: View {
    @Bindable var recipe: Recipe

    var body: some View {
        Form {
            Section("Recipe Name") {
                TextField("Recipe Name", text: $recipe.strMeal)
            }

            Section("Ingredients") {
                ForEach($recipe.ingredients) { $ingredient in
                    HStack {
                        if ingredient.isParsed {
                            TextField("Qty", value: $ingredient.measurementQty, format: .number)
                                .keyboardType(.decimalPad)

                            Picker("", selection: Binding(
                                get: { ingredient.measurementUnit ?? MeasurementUnit.none },
                                set: { ingredient.measurementUnit = $0 }
                            )) {
                                ForEach(MeasurementUnitCategory.allCases, id: \.self) { category in
                                    Section(category.rawValue) {
                                        ForEach(category.units, id: \.self) { unit in
                                            Text(unit.displayName).tag(unit)
                                        }
                                    }
                                }
                            }
                            .pickerStyle(.menu)

                            TextField("Ingredient Name", text: $ingredient.name, axis: .vertical)
                        } else {
                            Text(ingredient.measurementRaw)
                            Text(ingredient.name)
                        }

                        Spacer()
                        Button(role: .destructive) {
                            removeIngredient(ingredient)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                }

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
            }
        }
        .navigationTitle("Add a New Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }

    func addNewIngredient() {
        recipe.ingredients.append(Ingredient(name: "", measurementRaw: "", isParsed: true))
    }

    func removeIngredient(_ ingredient: Ingredient)	 {
        if let idx = recipe.ingredients.firstIndex(where: { $0.id == ingredient.id }) {
            recipe.ingredients.remove(at: idx)
        }
    }
}

#Preview {
    let ingredient1 = Ingredient(id: "1", name: "Tomato", measurementRaw: "2")
    let ingredient2 = Ingredient(id: "2", name: "Sugar", measurementRaw: "200g", measurementQty: 3, measurementUnit: MeasurementUnit.gram, isParsed: true)
    return AddRecipeView(recipe: Recipe(id: "", strMeal: "", strMealThumb: "", ingredients: [ingredient1, ingredient2]))
}
