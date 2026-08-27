import SwiftUI

struct ShoppingListInfoView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var list: ShoppingList
    @State private var showEditShoppingListSheet = false

    var sortedItems: [Binding<ShoppingListItem>] {
        $list.items.sorted { (lhs: Binding<ShoppingListItem>, rhs: Binding<ShoppingListItem>) in
            lhs.wrappedValue.name < rhs.wrappedValue.name
        }
    }

    /// Still a `List`: swiping an item away is the delete affordance this screen has, and a
    /// `ScrollView` of cards would take it away.
    var body: some View {
        List {
            ForEach(sortedItems, id: \.wrappedValue.id) { $item in
                Button {
                    item.purchased.toggle()
                } label: {
                    ShoppingListItemRowView(item: $item)
                }
                .buttonStyle(.plain)
                .padding(.vertical, Spacing.s)
                .listRowBackground(Color.surface)
                .listRowSeparatorTint(Color.border)
            }
            .onDelete(perform: deleteItem)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.surface)
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                showEditShoppingListSheet = true
            }
            .tint(Color.accent)
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
        ShoppingListItem(name: "Milk", measurement: "1 Gal"),
        ShoppingListItem(name: "Ice cream", measurement: "1 Pt"),
        ShoppingListItem(name: "Coke", measurement: "1 L"),
    ]
    let list = ShoppingList(name: "Target", items: shoppingList)

    NavigationStack {
        ShoppingListInfoView(list: list)
    }
}
