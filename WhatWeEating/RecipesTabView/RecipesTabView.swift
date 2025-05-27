//
//  RecipesView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/23/25.
//

import Kingfisher
import SwiftUI

struct RecipesTabView: View {
    @State private var vm = RecipesTabViewVM()
    @State private var selectedRecipesTabGroup = RecipesTabGroup.all
    @State private var selectedFoodCategory: FoodCategories?

    var body: some View {
        NavigationStack {
            Picker("Filter", selection: $selectedRecipesTabGroup) {
                Text("All").tag(RecipesTabGroup.all)
                Text("Favorites").tag(RecipesTabGroup.favorites)
                Text("My Recipes").tag(RecipesTabGroup.mine)
            }
            .pickerStyle(.segmented)
            .padding(.vertical)

            switch selectedRecipesTabGroup {
            case .all:
                if selectedFoodCategory != nil {
                    List(vm.recipes) { recipe in
                        HStack {
                            KFImage(URL(string: recipe.strMealThumb))
                                .resizable()
                                .frame(width: 64, height: 64)
                            Text(recipe.strMeal)
                        }

                    }
                    .listStyle(.plain)
                } else {
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
                }
            default:
                RecipeListView(selectedCategory: $selectedFoodCategory, selectedRecipesTab: $selectedRecipesTabGroup)
            }
        }
        .onChange(of: selectedFoodCategory) { oldCategory, newCategory in
            guard let newCategory else {
                return
            }

            Task {
                await vm.fetchRecipesByCategory(category: newCategory)
            }
        }
    }
}

#Preview {
    RecipesTabView()
}
