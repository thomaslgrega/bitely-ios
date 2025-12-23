//
//  AddRecipeView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/1/25.
//

import SwiftUI

struct EditRecipeView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var recipe: Recipe

    var body: some View {
        // TODO: Fields for calories, prep time, image, category (beef, etc)
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recipe name")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary700)

                    TextField("Recipe Name", text: $recipe.strMeal)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary200, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary700)

                    ForEach($recipe.ingredients) { $ingredient in
                        IngredientRowView(ingredient: $ingredient) {
                            removeIngredient(ingredient)
                        }
                        .padding()
                        .frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary200, lineWidth: 1)
                        )
                    }

                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(Color.primaryMain)
                        Button("Add an ingredient", action: addNewIngredient)
                    }
                }

                Spacer()
            }
            .padding()
            .toolbar {
                // TODO: Toolbar and alert for discard (cancel or discard)
                Button {
                    saveRecipe()
                } label: {
                    Text("Save")
                }
            }
        }
    }

    func addNewIngredient() {
        recipe.ingredients.append(Ingredient(name: "", measurement: ""))
    }

    func removeIngredient(_ ingredient: Ingredient) {
        if let idx = recipe.ingredients.firstIndex(where: { $0.id == ingredient.id }) {
            recipe.ingredients.remove(at: idx)
        }
    }

    func saveRecipe() {
        recipe.ingredients = recipe.ingredients.filter { $0.name.trimmingCharacters(in: .whitespaces) != "" }

        modelContext.insert(recipe)
        dismiss()
    }
}

#Preview {
    let ingredient1 = Ingredient(name: "Tomato", measurement: "2")
    let ingredient2 = Ingredient(name: "Sugar", measurement: "200g")

    NavigationStack {
        EditRecipeView(recipe: Recipe(id: "", strMeal: "", strMealThumb: "", ingredients: [ingredient1, ingredient2], calories: nil, totalCookTime: nil))
    }
}
