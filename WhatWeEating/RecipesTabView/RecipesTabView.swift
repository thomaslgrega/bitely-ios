//
//  RecipesView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/23/25.
//

import SwiftUI

struct RecipesTabView: View {
    @State private var vm = RecipesTabViewVM()
    @State private var selectedRecipesTabGroup = RecipesTabGroup.all
    @State private var selectedFoodCategory: FoodCategories?
    @State var selectedDate: Date

    var body: some View {
        NavigationStack {
            Text(selectedFoodCategory?.rawValue ?? "No Category")
            Picker("Filter", selection: $selectedRecipesTabGroup) {
                Text("All").tag(RecipesTabGroup.all)
                Text("Favorites").tag(RecipesTabGroup.favorites)
                Text("My Recipes").tag(RecipesTabGroup.mine)
            }
            .pickerStyle(.segmented)
            .padding(.vertical)

            if selectedRecipesTabGroup == RecipesTabGroup.all && selectedFoodCategory == nil {
                ScrollView {
                    ForEach(FoodCategories.allCases, id: \.self) { category in
                        VStack {
                            ZStack {
                                Image(category.rawValue.lowercased())

                                RoundedRectangle(cornerRadius: 15)
                                    .foregroundStyle(.black.opacity(0.3))

                                Text(category.rawValue)
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundStyle(.white)
                                    .padding()
                            }
                            .padding(.horizontal)
                        }
                        .onTapGesture {
                            selectedFoodCategory = category
                        }
                    }
                }
            } else {
                RecipeListView(selectedCategory: $selectedFoodCategory, selectedRecipesTab: $selectedRecipesTabGroup)
            }
        }
//        switch selectedRecipesTabGroup {
//        case .all:
//            Text("ALL RECIPES")
//        case .favorites:
//            Text("FAVORITE RECIPES")
//        case .mine:
//            Text("MY RECIPES")
//        }
    }
}

#Preview {
    RecipesTabView(selectedDate: Date.now)
}
