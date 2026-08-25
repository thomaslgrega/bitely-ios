//
//  RecipesView.swift
//  Bitely
//
//  Created by Thomas Grega on 4/23/25.
//

import SwiftUI

/// The route to the Pantry Item search. A value of its own rather than a
/// `FoodCategory`, since the search is not a category of the corpus.
struct PantrySearchDestination: Hashable {}

struct RecipesTabView: View {
    @State private var showSettingsSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                NavigationLink(value: PantrySearchDestination()) {
                    HStack {
                        Image(systemName: "basket.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.secondary50)
                            .padding()

                        VStack(alignment: .leading) {
                            Text("Cook what you have")
                                .foregroundStyle(Color.secondary50)
                                .font(.title2)
                                .bold()

                            Text("Search your saved recipes by the foods on hand")
                                .foregroundStyle(Color.primary100)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primaryMain)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .navigationDestination(for: PantrySearchDestination.self) { _ in
                    PantrySearchView()
                }

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
