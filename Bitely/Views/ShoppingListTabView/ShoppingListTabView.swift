import SwiftData
import SwiftUI

struct ShoppingListTabView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\ShoppingList.name)]) var shoppingLists: [ShoppingList]
    @State private var selectedList: ShoppingList?
    @State private var showSettingsSheet = false

    @State private var showAddShoppingListSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                contents
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.surface)
            .navigationTitle("Shopping Lists")
            .navigationDestination(item: $selectedList) { shoppingList in
                ShoppingListInfoView(list: shoppingList)
            }
            .sheet(isPresented: $showAddShoppingListSheet) {
                AddShoppingListView(shoppingList: ShoppingList(name: ""), onCreate: { _ in })
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(Color.contentPrimary)
                    .accessibilityLabel("Settings")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddShoppingListSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Color.accent)
                    .accessibilityLabel("New shopping list")
                }
            }
        }
    }

    @ViewBuilder
    private var contents: some View {
        if shoppingLists.isEmpty {
            EmptyState(
                systemImage: "basket",
                title: "No shopping lists yet",
                message: "Write one by hand, or build one from a recipe's ingredients.",
                actionTitle: "New shopping list"
            ) {
                showAddShoppingListSheet = true
            }
        } else {
            LazyVStack(spacing: Spacing.m) {
                ForEach(shoppingLists) { list in
                    ListRowCard(title: list.name, removeLabel: "Delete \(list.name)") {
                        selectedList = list
                    } onRemove: {
                        modelContext.delete(list)
                    }
                }
            }
            .padding(.top, Spacing.l)
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
        ShoppingList(name: "Safeway")
    ]

    for list in lists {
        container.mainContext.insert(list)
    }

    return ShoppingListTabView()
        .modelContainer(container)
}
