//
//  ContentView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/21/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Calendar", systemImage: "calendar") {
                CalendarTabView()
            }

            Tab("Shopping List", systemImage: "list.bullet.rectangle.portrait") {
                ShoppingListTabView()
            }

            Tab("Recipes", systemImage: "fork.knife") {
                RecipesTabView()
            }
        }
    }
}

#Preview {
    ContentView()
}
