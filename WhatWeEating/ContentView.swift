//
//  ContentView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/21/25.
//

import SwiftUI

enum mainTabs {
    case calendar
    case shoppingList
    case searchRecipes
    case bookmarkedRecipes
    case sharedRecipes
}

struct ContentView: View {
    @Environment(AuthStore.self) private var authStore

    @State private var showAuth = false
    @State private var selectedTab: mainTabs = .searchRecipes

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Recipes", systemImage: "fork.knife", value: .searchRecipes) {
                RecipesTabView()
            }

            Tab("Calendar", systemImage: "calendar", value: .calendar) {
                CalendarTabView()
            }

            Tab("Shopping List", systemImage: "basket", value: .shoppingList) {
                ShoppingListTabView()
            }

            Tab("Saved", systemImage: "bookmark", value: .bookmarkedRecipes) {
                SavedRecipesTabView()
            }

            Tab("Shared", systemImage: "square.and.arrow.up", value: .sharedRecipes) {
                SharedRecipesView()
            }
        }
        .tint(Color.primaryMain)
    }
}

#Preview {
    ContentView()
}
