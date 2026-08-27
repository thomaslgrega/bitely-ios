import SwiftData
import SwiftUI

struct RecipeShoppingListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @Query(sort: [SortDescriptor(\ShoppingList.name)]) var shoppingLists: [ShoppingList]
    @State var selectedShoppingList: ShoppingList?
    @State var items: [Ingredient]
    @State var itemsToAdd: [Ingredient] = []

    @State private var showAddNewShoppingListSheet = false
    @State private var showShoppingListPicker = false
    @State private var showRequiredWarning = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                if showRequiredWarning {
                    Label("Choose a shopping list", systemImage: "exclamationmark.triangle")
                        .textStyle(.meta)
                        .foregroundStyle(Color.destructive)
                }

                listPicker

                HStack {
                    Text("Ingredients")
                        .textStyle(.label)
                        .foregroundStyle(Color.contentSecondary)

                    Spacer()

                    Button("Select all", action: toggleSelectAll)
                        .buttonStyle(.textAction)
                }

                ingredients
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.surface)
        .navigationTitle("Choose Ingredients")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddNewShoppingListSheet) {
            AddShoppingListView(shoppingList: ShoppingList(name: "")) { shoppingList in
                selectedShoppingList = shoppingList
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", action: saveShoppingList)
                    .tint(Color.accent)
            }
        }
    }

    // MARK: - Choosing a Shopping List

    /// The choices expand in place rather than in a menu: creating a list is one of them,
    /// and it opens a sheet, which a `Menu` item cannot do without dismissing first.
    private var listPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy) { showShoppingListPicker.toggle() }
            } label: {
                HStack {
                    Text(selectedShoppingList?.name ?? "Select a shopping list")
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showShoppingListPicker ? 180 : 0))
                }
                .textStyle(.cardTitle)
                .foregroundStyle(Color.contentPrimary)
                .padding(Spacing.l)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showShoppingListPicker {
                ForEach(shoppingLists.filter { $0 != selectedShoppingList }) { list in
                    Divider().overlay(Color.border)

                    Button {
                        withAnimation(.snappy) { select(list) }
                    } label: {
                        Text(list.name)
                            .lineLimit(1)
                            .textStyle(.body)
                            .foregroundStyle(Color.contentPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.l)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Divider().overlay(Color.border)

                Button {
                    withAnimation(.snappy) {
                        showAddNewShoppingListSheet = true
                        showShoppingListPicker = false
                        showRequiredWarning = false
                    }
                } label: {
                    Label("Create a new shopping list", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.l)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.textAction)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .fill(Color.surfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .strokeBorder(showRequiredWarning ? Color.destructive : Color.border, lineWidth: 1)
        )
    }

    private func select(_ list: ShoppingList) {
        selectedShoppingList = list
        showShoppingListPicker = false
        showRequiredWarning = false
    }

    // MARK: - Choosing Ingredients

    private var ingredients: some View {
        LazyVStack(alignment: .leading, spacing: Spacing.m) {
            ForEach(items) { item in
                Button {
                    itemsToAdd.contains(item) ? removeFromItemList(item: item) : addToItemList(item: item)
                } label: {
                    HStack(spacing: Spacing.m) {
                        SelectionIndicator(isSelected: itemsToAdd.contains(item))

                        Text(item.name)
                            .textStyle(.cardTitle)

                        Text("(\(item.measurement))")
                            .textStyle(.meta)

                        Spacer()
                    }
                    .foregroundStyle(Color.contentPrimary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(SelectionState(isSelected: itemsToAdd.contains(item)).traits)
            }
        }
    }

    private func toggleSelectAll() {
        itemsToAdd = itemsToAdd.count == items.count ? [] : items
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
        guard let selectedShoppingList else {
            showRequiredWarning = true
            return
        }

        for item in itemsToAdd {
            selectedShoppingList.items.append(ShoppingListItem(name: item.name, measurement: item.measurement))
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        RecipeShoppingListView(items: [
            Ingredient(name: "Gnocchi", measurement: "500g"),
            Ingredient(name: "Sage", measurement: "1 bunch")
        ])
    }
}
