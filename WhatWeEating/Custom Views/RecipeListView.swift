//
//  RecipeListView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/29/25.
//

import SwiftUI

struct RecipeListView: View {
    @Binding var selectedCategory: FoodCategories?
    @Binding var selectedRecipesTab: RecipesTabGroup

    @State private var recipes = [Recipe]()

    var body: some View {
        List(recipes) { recipe in
            VStack {
                Text(recipe.name)
            }
        }
        .listStyle(.inset)
    }
}

#Preview {
    RecipeListView(selectedCategory: .constant(FoodCategories.Beef), selectedRecipesTab: .constant(RecipesTabGroup.all))
}
