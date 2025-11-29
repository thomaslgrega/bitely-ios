//
//  RecipesView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/23/25.
//

import SwiftUI

struct RecipesTabView: View {
    @State private var selectedFoodCategory: FoodCategories?

    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(FoodCategories.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        ZStack {
                            Image(category.rawValue.lowercased())
                                .resizable()
                                .scaledToFill()

                            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)

                            VStack {
                                Spacer()
                                Text(category.rawValue)
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundStyle(.white)
                            }
                            .padding()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding(.horizontal)
                    }
                }
                .navigationDestination(for: FoodCategories.self) { category in
                    RecipeListView(selectedCategory: category)
                }
            }
        }
    }
}

#Preview {
    RecipesTabView()
}
