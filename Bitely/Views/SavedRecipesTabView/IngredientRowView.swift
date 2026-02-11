//
//  IngredientRowView.swift
//  Bitely
//
//  Created by Thomas Grega on 12/5/25.
//

import SwiftUI

struct IngredientRowView: View {
    @State private var name = ""
    @State private var measurement = ""
    @Binding var ingredient: Ingredient
    var onDelete: () -> Void

    init(ingredient: Binding<Ingredient>, onDelete: @escaping () -> Void) {
        self._ingredient = ingredient
        self.onDelete = onDelete
        self._name = State(initialValue: ingredient.wrappedValue.name.trimmingCharacters(in: .whitespaces))
        self._measurement = State(initialValue: ingredient.wrappedValue.measurement.trimmingCharacters(in: .whitespaces))
    }

    var body: some View {
        HStack {
            TextField("e.g., flour", text: $ingredient.name)
                .textFieldStyle(.roundedBorder)

            TextField("e.g., 2 cups", text: $ingredient.measurement)
                .textFieldStyle(.roundedBorder)

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "minus.circle")
            }
            .foregroundStyle(Color.primaryMain)
            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    List {
        IngredientRowView(
            ingredient: .constant(Ingredient(name: "Lemon Juice", measurement: "1 cup")),
            onDelete: { }
        )
    }
}
