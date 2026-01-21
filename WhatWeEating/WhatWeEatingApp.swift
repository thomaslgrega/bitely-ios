//
//  WhatWeEatingApp.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/21/25.
//

import SwiftUI
import SwiftData

@main
struct WhatWeEatingApp: App {    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [Recipe.self, ShoppingList.self, MealPlanDay.self])
    }
}
