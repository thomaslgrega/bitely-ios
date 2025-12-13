//
//  ShoppingListTabView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/23/25.
//

import SwiftData
import SwiftUI

struct ShoppingListTabView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\ShoppingList.name)]) var shoppingLists: [ShoppingList]

    @State private var showAddShoppingListSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(shoppingLists) { list in
                    NavigationLink(value: list) {
                        Text(list.name)
                    }
                }
                .onDelete(perform: deleteList)
                .font(.title3)
            }
            .navigationDestination(for: ShoppingList.self) { shoppingList in
                ShoppingListInfoView(list: shoppingList)
            }
            .toolbar {
                Button("Add List") {
                    showAddShoppingListSheet = true
                }
            }
            .sheet(isPresented: $showAddShoppingListSheet) {
                AddShoppingListView(shoppingList: ShoppingList(name: ""), onCreate: { _ in })
            }
        }
    }

    func deleteList(_ offset: IndexSet) {
        for index in offset {
            let list = shoppingLists[index]
            modelContext.delete(list)
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ShoppingList.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let list1 = ShoppingList(name: "Target")
    let list2 = ShoppingList(name: "Costco")

    container.mainContext.insert(list1)
    container.mainContext.insert(list2)

    return ShoppingListTabView()
        .modelContainer(container)
}
