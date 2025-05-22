//
//  CalendarTabView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/29/25.
//

import SwiftUI

struct CalendarTabView: View {
    @State private var recipes = [String]()
    @State private var selectedDate = Date()
    @State private var showRecipeSheet = false

    @Binding var selectedTab: Int

    var body: some View {
        VStack {
            CalendarView(selectedDate: $selectedDate)
                .onChange(of: selectedDate) { oldValue, newValue in
                    let calendar = Calendar.current
                    let day = calendar.component(.dayOfYear, from: newValue)
                    let year = calendar.component(.year, from: newValue)
                    recipes = testStore[day + year] ?? []
                    print(selectedDate)
                }

            Button("Add Meal", systemImage: "plus.circle") {
                showRecipeSheet = true
            }
            .padding()
            .background(.blue)
            .cornerRadius(5)
            .foregroundStyle(.white)
            .bold()
        }
        .sheet(isPresented: $showRecipeSheet) {
            RecipesTabView(selectedDate: selectedDate)
        }
    }

    // 2303732497199187946
    let testStore: [Int: [String]] = [
        2166: ["cereal", "sandwich"],
        2167: ["ribs", "pho"],
        2168: ["steak", "avocado toast"]
    ]

    // Maybe store into SwiftData/CoreData, etc as:
    // [year + day: [Recipes] ]
}

#Preview {
    CalendarTabView(selectedTab: .constant(1))
}
