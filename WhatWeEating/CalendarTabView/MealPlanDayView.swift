//
//  MealPlanDayView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/17/25.
//

import SwiftUI

struct MealPlanDayView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var mealPlanDay: MealPlanDay
    @State private var showSavedRecipesSheet = false
    @State private var showRecipeInfoSheet = false
    @State private var selectedMealType: MealType = .breakfast

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(MealType.allCases, id: \.self) { type in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(type.rawValue)
                            .font(.largeTitle)

                        Spacer()

                        Button {
                            showSavedRecipesSheet = true
                            selectedMealType = type
                        } label: {
                            Image(systemName: "plus")
                        }
                        .font(.title)
                        .bold()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(Color.primaryMain)
                    }
//                    .padding(.vertical)

                    if mealPlanDay[type].isEmpty {
                        Text("You don't have any meals planned for \(type.rawValue)")
                            .foregroundStyle(Color.secondary400)
                            .italic()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(mealPlanDay[type]) { recipe in
                                CustomListCardView(mainText: recipe.strMeal, trailingIcon: "trash") {
                                    showRecipeInfoSheet = true
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .foregroundStyle(Color.secondaryMain)
        .sheet(isPresented: $showSavedRecipesSheet) {
            AddToMealPlanDaySheet(mealType: selectedMealType, addRecipeToCalendar: addRecipeToCalendar)
        }
        .sheet(isPresented: $showRecipeInfoSheet) {
//            RecipeInfoView(savedRecipeIds: <#T##Set<String>#>, recipeId: <#T##String#>)
        }
    }

    func addRecipeToCalendar(_ recipe: Recipe, _ mealType: MealType) {
        mealPlanDay[mealType].append(recipe)
    }
}

#Preview {
    let mealPlanDay = MealPlanDay(dayKey: Date().dayKey)
    ScrollView {
        MealPlanDayView(mealPlanDay: mealPlanDay)
            .padding(.horizontal)
    }
}
