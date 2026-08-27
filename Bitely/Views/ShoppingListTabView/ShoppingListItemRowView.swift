import SwiftUI

struct ShoppingListItemRowView: View {
    @Binding var item: ShoppingListItem

    var body: some View {
        HStack(spacing: Spacing.m) {
            SelectionIndicator(isSelected: item.purchased)

            Text(item.name)
                .textStyle(.cardTitle)
                .strikethrough(item.purchased)

            Text("(\(item.measurement))")
                .textStyle(.meta)
                .strikethrough(item.purchased)

            Spacer()
        }
        .foregroundStyle(item.purchased ? Color.contentSecondary : Color.contentPrimary)
    }
}

#Preview {
    let purchased = ShoppingListItem(name: "Ice cream", measurement: "1 Pt")
    purchased.purchased = true

    return VStack(spacing: Spacing.l) {
        ShoppingListItemRowView(item: .constant(ShoppingListItem(name: "Milk", measurement: "1 Gal")))
        ShoppingListItemRowView(item: .constant(purchased))
    }
    .padding()
    .background(Color.surface)
}
