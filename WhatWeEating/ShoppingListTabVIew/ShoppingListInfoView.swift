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
    @State private var showEditShoppingListSheet = false

    var sortedItems: [Binding<ShoppingListItem>] {
        $list.items.sorted { (lhs: Binding<ShoppingListItem>, rhs: Binding<ShoppingListItem>) in
            lhs.wrappedValue.ingredient.name < rhs.wrappedValue.ingredient.name
        }
    }

    var body: some View {
        List {
            ForEach(sortedItems, id: \.wrappedValue.id) { $item in
                Button {
                    item.purchased.toggle()
                } label: {
                    ShoppingListItemRowView(item: $item)
                }
                .buttonStyle(.plain)
                .foregroundStyle(item.purchased ? Color.secondary400 : Color.secondaryMain)
                .font(.title3)
                .padding(.vertical)
            }
            .onDelete(perform: deleteItem)
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                showEditShoppingListSheet = true
            }
        }
        .sheet(isPresented: $showEditShoppingListSheet) {
            AddShoppingListView(shoppingList: list, onCreate: { _ in })
        }
    }

    func deleteItem(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { sortedItems[$0] }

        for item in itemsToDelete {
            list.items.removeAll { $0.id == item.id }
        }
    }
}

#Preview {
    let shoppingList = [
        ShoppingListItem(ingredient: Ingredient(name: "Milk", measurement: "1 Gal")),
        ShoppingListItem(ingredient: Ingredient(name: "Ice cream", measurement: "1 Pt")),
        ShoppingListItem(ingredient: Ingredient(name: "Coke", measurement: "1 L")),
    ]
    let list = ShoppingList(name: "Target", items: shoppingList, image: "")
    ShoppingListInfoView(list: list)
}
