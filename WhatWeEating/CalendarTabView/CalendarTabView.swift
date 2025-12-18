//
//  CalendarTabView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/29/25.
//

import SwiftData
import SwiftUI

struct CalendarTabView: View {
    @Environment(\.modelContext) var modelContext
    @State private var recipes = [String]()
    @State private var selectedDate = Date()
    @Query var mealPlanDays: [MealPlanDay]

    var selectedDateMealPlan: MealPlanDay? {
        mealPlanDays.first(where: { $0.dayKey == selectedDate.dayKey })
    }

    var body: some View {
        DatePickerView(selectedDate: $selectedDate)
            .tint(Color.primaryMain)

        Divider()

        ScrollView {
            if let mealPlanDay = selectedDateMealPlan {
                MealPlanDayView(mealPlanDay: mealPlanDay)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loadMealPlanDay()
        }
        .onChange(of: selectedDate) { _, _ in
            loadMealPlanDay()
        }
    }

    func loadMealPlanDay() {
        if selectedDateMealPlan == nil {
            let newMealPlanDay = MealPlanDay(dayKey: selectedDate.dayKey)
            modelContext.insert(newMealPlanDay)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MealPlanDay.self, configurations: config)
    CalendarTabView()
        .modelContainer(container)
}
