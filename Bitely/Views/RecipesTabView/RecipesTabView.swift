//
//  RecipesView.swift
//  Bitely
//
//  Created by Thomas Grega on 4/23/25.
//

import SwiftUI

struct RecipesTabView: View {
    @State private var showSettingsSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(FoodCategory.allCases, id: \.self) { category in
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
                .navigationDestination(for: FoodCategory.self) { category in
                    RecipeListView(selectedCategory: category)
                }
            }
            .navigationTitle("Find a recipe")
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
            .toolbar {
                Button {
                    showSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Color.primaryMain)
                }
            }
        }
    }
}

#Preview {
    RecipesTabView()
}
