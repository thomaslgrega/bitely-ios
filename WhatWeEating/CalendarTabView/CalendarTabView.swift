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

    var body: some View {
        ScrollView {
            CalendarView(selectedDate: $selectedDate)
                .tint(.orange)
                .onChange(of: selectedDate) { oldValue, newValue in
                    let calendar = Calendar.current
                    let day = calendar.component(.dayOfYear, from: newValue)
                    let year = calendar.component(.year, from: newValue)
                    recipes = testStore[day + year] ?? []
                }

            Divider()

            VStack(alignment: .leading) {
                Section("Breakfast") {
                    
                }
                Section("Lunch") {

                }

                Section("Dinner") {

                }

                HStack {
                    Spacer()
                    Button("Add Meal", systemImage: "plus.circle") {
                        showRecipeSheet = true
                    }
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.white)
                    .cornerRadius(5)
                    .bold()

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

        }
        .sheet(isPresented: $showRecipeSheet) {
            SavedRecipesTabView()
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
    CalendarTabView()
}
