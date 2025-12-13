//
//  ShoppingListItem.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/9/25.
//

import Foundation
import SwiftData

@Model
class ShoppingListItem: Identifiable {
    @Attribute(.unique) var id = UUID()
    var ingredient: Ingredient
    var purchased: Bool = false

    init(ingredient: Ingredient) {
        self.ingredient = ingredient
    }
}
