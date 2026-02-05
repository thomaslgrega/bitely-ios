//
//  ShoppingList.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/8/25.
//

import Foundation
import SwiftData

@Model
class ShoppingList {
    @Attribute(.unique) var id = UUID()
    var name: String

    @Relationship(deleteRule: .cascade)
    var items: [ShoppingListItem]

    init(name: String, items: [ShoppingListItem] = []) {
        self.name = name
        self.items = items
    }
}
