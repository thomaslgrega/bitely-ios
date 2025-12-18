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
    @State private var selectedList: ShoppingList?

    @State private var showAddShoppingListSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    ForEach(shoppingLists) { list in
                        CustomListCardView(mainText: list.name, trailingIcon: "trash") {
                            selectedList = list
                        } iconOnTapAction: {
                            modelContext.delete(list)
                        }
                    }
                    .font(.title3)

                    Spacer()
                }
                .foregroundStyle(Color.secondaryMain)
                .padding()
                .navigationTitle("Shopping Lists")
                .navigationDestination(item: $selectedList) { shoppingList in
                    ShoppingListInfoView(list: shoppingList)
                }
                .sheet(isPresented: $showAddShoppingListSheet) {
                    AddShoppingListView(shoppingList: ShoppingList(name: ""), onCreate: { _ in })
                }

                VStack {
                    Spacer()

                    HStack {
                        Spacer()
                        Button {
                            showAddShoppingListSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(Color.secondary100)
                                .font(.title)
                        }
                        .frame(width: 50, height: 50)
                        .background(Color.primaryMain)
                        .clipShape(Circle())
                    }
                    .padding(32)
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ShoppingList.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let lists = [
        ShoppingList(name: "Target"),
        ShoppingList(name: "Costco"),
        ShoppingList(name: "Walmart"),
        ShoppingList(name: "Safeway"),
        ShoppingList(name: "Target"),
        ShoppingList(name: "Costco"),
        ShoppingList(name: "Walmart"),
        ShoppingList(name: "Safeway"),
        ShoppingList(name: "Target"),
        ShoppingList(name: "Costco"),
        ShoppingList(name: "Walmart"),
        ShoppingList(name: "Safeway"),
        ShoppingList(name: "Target"),
        ShoppingList(name: "Costco"),
        ShoppingList(name: "Walmart"),
        ShoppingList(name: "Safeway"),
    ]

    for list in lists {
        container.mainContext.insert(list)
    }

    return ShoppingListTabView()
        .modelContainer(container)
}
