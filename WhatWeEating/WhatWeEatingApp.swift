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
    private let authStore: AuthStore
    private let authService: AuthService
    private let recipeService: RecipeService

    init() {
        let store = AuthStore()
        let client = APIClient(authStore: store)

        self.authStore = store
        self.authService = AuthService(api: client, authStore: store)
        self.recipeService = RecipeService(api: client)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environment(authStore)
                .environment(authService)
                .environment(recipeService)
                .task {
                    await authService.bootstrap()
                }
        }
        .modelContainer(for: [Recipe.self, ShoppingList.self, MealPlanDay.self])
    }
}
