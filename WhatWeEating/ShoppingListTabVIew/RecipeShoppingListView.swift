//
//  addToShoppingListView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/8/25.
//

import SwiftUI
import SwiftData

struct RecipeShoppingListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @Query(sort: [SortDescriptor(\ShoppingList.name)]) var shoppingLists: [ShoppingList]
    @State var selectedShoppingList: ShoppingList?

    @State var showAddNewShoppingListSheet: Bool = false
    @State var items: [Ingredient]
    @State var itemsToAdd: [Ingredient] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Select a shopping list", selection: $selectedShoppingList) {
                        Text("Select a shopping list")
                            .tag(nil as ShoppingList?)
                            .disabled(true)

                        ForEach(shoppingLists) { shoppingList in
                            Text(shoppingList.name)
                                .tag(shoppingList)
                        }
                    }

                    Button {
                        showAddNewShoppingListSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create a new shopping list")
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .font(.title2)
                    .padding(.vertical)

                    Divider()
                        .frame(height: 1)
                        .overlay(.gray)
                        .padding(.bottom)

                    Button("Select all") {
                        if itemsToAdd.count == items.count {
                            itemsToAdd = []
                        } else {
                            itemsToAdd = items
                        }
                    }
                    .font(.subheadline)

                    ForEach(items) { item in
                        Divider()
                        itemRow(for: item)
                            .foregroundStyle(.primary)
                    }

                    Spacer()
                }
                .font(.title2)
                .padding()
            }
            .navigationTitle("Choose Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddNewShoppingListSheet) {
                AddShoppingListView(selectedShoppingList: $selectedShoppingList)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        saveShoppingList()
                    }
                }
            }
        }
    }

    func itemRow(for item: Ingredient) -> some View {
        HStack {
            Button {
                itemsToAdd.contains(item) ? removeFromItemList(item: item) : addToItemList(item: item)
            } label: {
                HStack {
                    Image(systemName: itemsToAdd.contains(item) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(itemsToAdd.contains(item) ? .green : .primary)

                    Text(item.name)
                        .bold()

                    Text("(\(item.measurementRaw))")
                }
            }
        }
        .foregroundStyle(.primary)
    }

    func removeFromItemList(item: Ingredient) {
        if let idx = itemsToAdd.firstIndex(where: { $0 == item }) {
            itemsToAdd.remove(at: idx)
        }
    }

    func addToItemList(item: Ingredient) {
        itemsToAdd.append(item)
    }

    func saveShoppingList() {
        // TODO: save shopping list (Add the items: [Ingredients] Array to selected shopping list)
        if let selectedShoppingList {
            for item in itemsToAdd {
                selectedShoppingList.items.append(ShoppingListItem(ingredient: item))
            }
            modelContext.insert(selectedShoppingList)
            dismiss()
        }
    }
}

#Preview {
    RecipeShoppingListView(items: [])
}
