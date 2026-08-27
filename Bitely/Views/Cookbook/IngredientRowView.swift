import SwiftUI

struct IngredientRowView: View {
    @Binding var ingredient: Ingredient
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.m) {
            TextField("e.g., flour", text: $ingredient.name)

            TextField("e.g., 2 cups", text: $ingredient.measurement)

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
    IngredientRowView(
        ingredient: .constant(Ingredient(name: "Lemon Juice", measurement: "1 cup")),
        onDelete: {}
    )
    .fieldSurface()
    .padding()
    .background(Color.surface)
}
