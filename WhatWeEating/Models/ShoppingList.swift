//
//  ShoppingList.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/8/25.
//

import Foundation
import SwiftData

@Model
class ShoppingList: Identifiable {
    var id: String
    var name: String

    @Relationship(deleteRule: .cascade)
    var items: [ShoppingListItem]

    var image: String?

    init(name: String, items: [ShoppingListItem] = [], image: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.items = items
        self.image = image
    }
}
