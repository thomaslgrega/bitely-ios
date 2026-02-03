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
    @State private var showDeleteAlert = false
    @State private var selectedRecipe: Recipe?
    @State private var selectedMealType: MealType?

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(MealType.allCases, id: \.self) { type in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(type.rawValue)
                            .font(.largeTitle)

                        Spacer()

                        Button {
                            selectedMealType = type
                        } label: {
                            Image(systemName: "plus")
                        }
                        .font(.title)
                        .bold()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(Color.primaryMain)
                    }

                    if mealPlanDay[type].isEmpty {
                        Text("You don't have any meals planned for \(type.rawValue)")
                            .foregroundStyle(Color.secondary400)
                            .italic()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(mealPlanDay[type]) { recipe in
                                CustomListCardView(mainText: recipe.name, trailingIcon: "minus.circle") {
                                    selectedRecipe = recipe
                                } iconOnTapAction: {
                                    showDeleteAlert = true
                                }
                                .alert("Remove \(recipe.name) from \(type.rawValue.lowercased())?", isPresented: $showDeleteAlert) {
                                    Button("Cancel", role: .cancel) { }
                                    Button("Delete", role: .destructive) {
                                        removeRecipeFromCalendar(recipe, type)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .foregroundStyle(Color.secondaryMain)
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
    ScrollView {
        MealPlanDayView(mealPlanDay: mealPlanDay)
            .padding(.horizontal)
    }
}
