//
//  ShoppingListItemRowView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/12/25.
//

import SwiftUI

struct ShoppingListItemRowView: View {
    @Binding var item: ShoppingListItem

    var body: some View {
        HStack {
            Image(systemName: item.purchased ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.purchased ? .orange : .primary)
            Text(item.ingredient.name)
                .strikethrough(item.purchased ? true : false)
            Text("(\(item.ingredient.measurementRaw))")
        }
    }
}

#Preview {
    let item = ShoppingListItem(ingredient: Ingredient(name: "Milk", measurementRaw: "1 Gal"))
    ShoppingListItemRowView(item: .constant(item))
}
