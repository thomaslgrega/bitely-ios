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
    @State private var showShoppingListPicker = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.snappy) {
                            showShoppingListPicker.toggle()
                        }
                    } label: {
                        HStack {
                            Text(selectedShoppingList?.name ?? "Select a shopping list")
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(showShoppingListPicker ? 180 : 0))
                        }
                        .padding()
                    }

                    if showShoppingListPicker {
                        ForEach(shoppingLists) { list in
                            if list != selectedShoppingList {
                                Divider()
                                    .background(Color.secondary50)
                                    .frame(width: 230)
                                    .padding(.horizontal)
                                Button {
                                    withAnimation(.snappy) {
                                        selectedShoppingList = list
                                        showShoppingListPicker = false
                                    }
                                } label: {
                                    Text(list.name)
                                        .lineLimit(1)
                                }
                                .padding()
                            }
                        }

                        Divider()
                            .background(Color.secondary50)
                            .frame(width: 230)
                            .padding(.horizontal)

                        Button {
                            withAnimation(.snappy) {
                                showAddNewShoppingListSheet = true
                                showShoppingListPicker = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Create a new shopping list")
                            }
                            .padding()
                        }
                    }
                }
                .zIndex(1000)
                .background(showShoppingListPicker ? Color.secondary200 : Color.primaryMain)
                .foregroundStyle(showShoppingListPicker ? Color.primaryMain : Color.secondary100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                .shadow(radius: showShoppingListPicker ? 2 : 0)

                VStack(alignment: .leading) {
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

                    ScrollView {
                        ForEach(items) { item in
                            Divider()
                            itemRow(for: item)
                                .foregroundStyle(.primary)
                        }

                        Spacer()
                    }
                }
                .offset(y: 80)
                .padding()
            }
            .navigationTitle("Choose Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddNewShoppingListSheet) {
                AddShoppingListView(shoppingList: ShoppingList(name: "")) { shoppingList in
                    selectedShoppingList = shoppingList
                }
            }
            .toolbar {
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
                        .foregroundStyle(itemsToAdd.contains(item) ? Color.primaryMain : .secondaryMain)

                    Text(item.name)
                        .bold()

                    Text("(\(item.measurement))")

                    Spacer()
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
