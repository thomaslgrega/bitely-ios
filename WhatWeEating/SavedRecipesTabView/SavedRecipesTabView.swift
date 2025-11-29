//
//  SavedRecipesTabView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 11/28/25.
//

import SwiftData
import SwiftUI

struct SavedRecipesTabView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\Recipe.strMeal)]) var recipes: [Recipe]

    @State private var vm = SavedRecipesTabViewVM()

    var body: some View {
        NavigationStack {
            List {
                ForEach(recipes) { recipe in
                    Text(recipe.strMeal)
                }
                .onDelete(perform: deleteSavedRecipe)
            }
        }
    }

    func deleteSavedRecipe(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(recipes[index])
        }
    }
}

#Preview {
    SavedRecipesTabView()
}
