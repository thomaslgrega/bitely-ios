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
                VStack(alignment: .leading, spacing: Spacing.xxxl) {
                    FormField(label: "Name") {
                        TextField("Costco, Target, etc.", text: $shoppingList.name)
                            .textStyle(.body)
                    }

                    items
                }
                .padding(Spacing.xl)
            }
            .background(Color.surface)
            .navigationTitle("New shopping list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(Color.contentPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: saveShoppingList)
                        .tint(Color.accent)
                }
            }
            .toolbarBackground(Color.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var items: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Ingredients")
                .textStyle(.label)
                .foregroundStyle(Color.contentSecondary)

            ForEach($shoppingList.items) { $item in
                ShoppingListItemFormRow(shoppingListItem: $item) {
                    removeItemFromShoppingList(item)
                }
                .fieldSurface()
            }

            ForEach($itemsToAdd) { $item in
                ShoppingListItemFormRow(shoppingListItem: $item) {
                    removeItemFromItemsToAdd(item)
                }
                .fieldSurface()
            }

            Button(action: addItem) {
                Label("Add an ingredient", systemImage: "plus.circle")
            }
            .buttonStyle(.textAction)
            .padding(.top, Spacing.xs)
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
