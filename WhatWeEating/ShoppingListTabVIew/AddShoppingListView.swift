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
    @Binding var selectedShoppingList: ShoppingList?
    @State var name: String = ""
    @State var items: [ShoppingListItem] = []

    var body: some View {
        NavigationStack {
            Form {
                //TODO: Image field

                Section {
                    TextField("Name", text: $name)
                }

                Section("Ingredients") {
                    ForEach($items) { $item in
                        IngredientRowView(
                            ingredient: $item.ingredient,
                            onDelete: { removeItem(item) }
                        )
                    }

                    if items.count < 20 {
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
        items.removeAll { $0.id == item.id }
    }

    func addItem() {
        let newIngredient = Ingredient(name: "", measurementRaw: "", isParsed: true)
        items.append(ShoppingListItem(ingredient: newIngredient))
    }

    func saveShoppingList() {
        //TODO: Add image
        //TODO: Add check for shopping Lists with no name. Either a default name or stop users from creating
        if name == "" {
            name = "Shopping List"
        }

        items = items.filter({ $0.ingredient.name != "" })
        let newShoppingList = ShoppingList(name: name, items: items)
        modelContext.insert(newShoppingList)
        selectedShoppingList = newShoppingList
        dismiss()
    }
}

#Preview {
    AddShoppingListView(selectedShoppingList: .constant(ShoppingList(name: "Target")))
}
