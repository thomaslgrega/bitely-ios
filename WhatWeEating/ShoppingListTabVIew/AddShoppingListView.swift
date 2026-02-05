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
    @State private var itemsToAdd: [ShoppingListItem] = [ShoppingListItem(name: "", measurement: "")]

    var onCreate: (ShoppingList) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .foregroundStyle(Color.secondary700)
                            .font(.subheadline)

                        TextField("Costco, Target, etc.", text: $shoppingList.name)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                            .textFieldStyle(.roundedBorder)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary200, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .foregroundStyle(Color.secondary700)
                            .font(.subheadline)

                        ForEach($shoppingList.items) { $item in
                            ShoppingListItemFormRow(shoppingListItem: $item) {
                                removeItemFromShoppingList(item)
                            }
                            .padding()
                            .frame(height: 54)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary200, lineWidth: 1)
                            )
                        }

                        ForEach($itemsToAdd) { $item in
                            ShoppingListItemFormRow(shoppingListItem: $item) {
                                removeItemFromItemsToAdd(item)
                            }
                            .padding()
                            .frame(height: 54)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary200, lineWidth: 1)
                            )
                        }

                        HStack {
                            Image(systemName: "plus.circle")
                            Button("Add an ingredient", action: addItem)
                        }
                        .foregroundStyle(Color.primaryMain)
                    }
                }
                .padding()
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

    func removeItemFromShoppingList(_ item: ShoppingListItem) {
        shoppingList.items.removeAll { $0.id == item.id }
    }

    func removeItemFromItemsToAdd(_ item: ShoppingListItem) {
        itemsToAdd.removeAll { $0.id == item.id }
    }

    func addItem() {
        itemsToAdd.append(ShoppingListItem(name: "", measurement: ""))
    }

    func saveShoppingList() {
        if shoppingList.name == "" {
            shoppingList.name = "Shopping List"
        }

        shoppingList.items = shoppingList.items.filter { $0.name.trimmingCharacters(in: .whitespaces) != "" }
        itemsToAdd = itemsToAdd.filter { $0.name.trimmingCharacters(in: .whitespaces) != "" }

        for item in itemsToAdd {
            shoppingList.items.append(item)
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
