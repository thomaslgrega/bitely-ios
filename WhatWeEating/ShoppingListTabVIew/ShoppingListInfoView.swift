//
//  ShoppingListInfoView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/10/25.
//

import SwiftUI

struct ShoppingListInfoView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var list: ShoppingList

    var body: some View {
        List {
            ForEach(list.items) { item in
                Button {
                    item.purchased.toggle()
                } label: {
                    HStack {
                        Image(systemName: item.purchased ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.purchased ? .orange : .primary)
                        Text(item.ingredient.name)
                            .strikethrough(item.purchased ? true : false)
                        Text("(\(item.ingredient.measurementRaw))")
                    }
                }
                .foregroundStyle(item.purchased ? .tertiary : .primary)
                .bold(!item.purchased)
                .font(.title3)
                .padding(.vertical)
            }
            .onDelete(perform: deleteItem)
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            let item = list.items[index]
            list.items.remove(at: index)
            modelContext.delete(item)
        }
    }
}

#Preview {
    let shoppingList = [
        ShoppingListItem(ingredient: Ingredient(name: "Milk", measurementRaw: "1 Gal")),
        ShoppingListItem(ingredient: Ingredient(name: "Ice cream", measurementRaw: "1 Pt")),
        ShoppingListItem(ingredient: Ingredient(name: "Coke", measurementRaw: "1 L")),
    ]
    let list = ShoppingList(name: "Target", items: shoppingList, image: "")
    ShoppingListInfoView(list: list)
}
