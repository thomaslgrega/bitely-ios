//
//  ContentView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/21/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Calendar", systemImage: "calendar", value: 0) {
                CalendarTabView(selectedTab: $selectedTab)
            }

            Tab("Shopping List", systemImage: "list.bullet.rectangle.portrait", value: 1) {
                ShoppingListTabView()
            }

            Tab("Recipes", systemImage: "fork.knife", value: 2) {
                RecipesTabView()
            }

            Tab("Saved", systemImage: "bookmark", value: 3) {
                SavedRecipesTabView()
            }
        }
    }
}

#Preview {
    ContentView()
}
