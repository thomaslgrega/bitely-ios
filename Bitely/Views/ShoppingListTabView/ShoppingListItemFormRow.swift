import SwiftUI

struct ShoppingListItemFormRow: View {
    @Binding var shoppingListItem: ShoppingListItem
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.m) {
            TextField("e.g., flour", text: $shoppingListItem.name)

            TextField("e.g., 2 cups", text: $shoppingListItem.measurement)

            Button(action: onDelete) {
                Image(systemName: "minus.circle")
                    .font(.system(size: SymbolSize.control, weight: .medium))
                    .foregroundStyle(Color.destructive)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove this ingredient")
        }
        .textStyle(.body)
        .foregroundStyle(Color.contentPrimary)
    }
}

#Preview {
    ShoppingListItemFormRow(
        shoppingListItem: .constant(ShoppingListItem(name: "Lemon Juice", measurement: "1 cup")),
        onDelete: {}
    )
    .fieldSurface()
    .padding()
    .background(Color.surface)
}
