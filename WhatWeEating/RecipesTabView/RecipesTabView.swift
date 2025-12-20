//
//  RecipesView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/23/25.
//

import SwiftUI

struct RecipesTabView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(FoodCategories.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        HStack {
                            Image(category.rawValue.lowercased())
                                .resizable()
                                .scaledToFit()
                                .padding()

                            Text(category.rawValue)
                                .foregroundStyle(Color.secondaryMain)
                                .font(.title)

                            Spacer()

                            ZStack {
                                Capsule()
                                    .frame(width: 40, height: 32)
                                    .foregroundStyle(Color.primaryMain)

                                Image(systemName: "arrow.right")
                                    .foregroundStyle(Color.secondary100)
                                    .bold()
                            }
                            .padding(.trailing)
                        }
                    }
                    .frame(maxHeight: 100, alignment: .leading)
                    .background(Color.secondary100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary200, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .navigationDestination(for: FoodCategories.self) { category in
                    RecipeListView(selectedCategory: category)
                }
            }
            .navigationTitle("Find a recipe")
        }
    }
}

#Preview {
    RecipesTabView()
}
