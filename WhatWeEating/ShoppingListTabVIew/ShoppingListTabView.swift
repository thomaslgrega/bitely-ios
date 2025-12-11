//
//  ShoppingListTabView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/23/25.
//

import SwiftData
import SwiftUI

struct ShoppingListTabView: View {
    @Query(sort: [SortDescriptor(\ShoppingList.name)]) var shoppingLists: [ShoppingList]

    var body: some View {
        NavigationStack {
            List {
                ForEach(shoppingLists) { list in
                    NavigationLink(value: list) {
                        Text(list.name)
                    }
                }
            }
            .navigationDestination(for: ShoppingList.self) { shoppingList in
                ShoppingListInfoView(list: shoppingList)
            }
        }
    }
}

#Preview {
    ShoppingListTabView()
}
