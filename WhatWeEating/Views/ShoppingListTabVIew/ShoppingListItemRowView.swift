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
                .foregroundStyle(item.purchased ? Color.primaryMain : Color.secondaryMain)

            Text(item.name)
                .strikethrough(item.purchased)

            Text("(\(item.measurement))")
                .strikethrough(item.purchased)
        }
    }
}

#Preview {
    let item = ShoppingListItem(name: "Milk", measurement: "1 Gal")
    ShoppingListItemRowView(item: .constant(item))
}
