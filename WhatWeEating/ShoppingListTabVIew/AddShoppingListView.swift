//
//  AddShoppingListSheet.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/9/25.
//

import SwiftUI

struct AddShoppingListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Bindable var shoppingList: ShoppingList

    var onCreate: (ShoppingList) -> Void

    var body: some View {
        NavigationStack {
            Form {
                //TODO: Image field

                Section("Name") {
                    TextField("Costco, Target, etc.", text: $shoppingList.name)
                }

                Section("Ingredients") {
                    ForEach($shoppingList.items) { $item in
                        IngredientRowView(
                            ingredient: $item.ingredient,
                            onDelete: { removeItem(item) }
                        )
                    }

                    if shoppingList.items.count < 20 {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.blue)
                            Button("Add an ingredient", action: addItem)
                        }
                    }
                }
            }
            .navigationTitle("Create a new Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveShoppingList()
                    }
                }
            }
        }
    }

    func removeItem(_ item: ShoppingListItem) {
        shoppingList.items.removeAll { $0.id == item.id }
    }

    func addItem() {
        let newIngredient = Ingredient(name: "", measurementRaw: "", isParsed: true)
        shoppingList.items.append(ShoppingListItem(ingredient: newIngredient))
    }

    func saveShoppingList() {
        //TODO: Add image
        if shoppingList.name == "" {
            shoppingList.name = "Shopping List"
        }

        shoppingList.items = shoppingList.items.filter({ $0.ingredient.name != "" })
        shoppingList.items = shoppingList.items.map { item in
            if let qty = item.ingredient.measurementQty {
                if let unit = item.ingredient.measurementUnit {
                    item.ingredient.measurementRaw = "\(qty.trimTrailingZeros()) \(unit)"
                } else {
                    item.ingredient.measurementRaw = "\(qty)"
                }
            }

            return item
        }

        modelContext.insert(shoppingList)
        onCreate(shoppingList)
        dismiss()
    }
}

#Preview {
    let list = ShoppingList(name: "Target")
    AddShoppingListView(shoppingList: list, onCreate: { _ in })
}
