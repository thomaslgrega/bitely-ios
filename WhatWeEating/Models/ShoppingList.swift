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

    var image: String?

    init(name: String, items: [ShoppingListItem] = [], image: String? = nil) {
        self.name = name
        self.items = items
        self.image = image
    }
}
