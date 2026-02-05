//
//  ShoppingListItemFormRow.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 2/4/26.
//

import SwiftUI

struct ShoppingListItemFormRow: View {
    @State private var name = ""
    @State private var measurement = ""
    @Binding var shoppingListItem: ShoppingListItem
    var onDelete: () -> Void

    init(shoppingListItem: Binding<ShoppingListItem>, onDelete: @escaping () -> Void) {
        self._shoppingListItem = shoppingListItem
        self.onDelete = onDelete
        self._name = State(initialValue: shoppingListItem.wrappedValue.name.trimmingCharacters(in: .whitespaces))
        self._measurement = State(initialValue: shoppingListItem.wrappedValue.measurement.trimmingCharacters(in: .whitespaces))
    }

    var body: some View {
        HStack {
            TextField("e.g., flour", text: $shoppingListItem.name)
                .textFieldStyle(.roundedBorder)

            TextField("e.g., 2 cups", text: $shoppingListItem.measurement)
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
        ShoppingListItemFormRow(
            shoppingListItem: .constant(ShoppingListItem(name: "Lemon Juice", measurement: "1 cup")),
            onDelete: { }
        )
    }
}
