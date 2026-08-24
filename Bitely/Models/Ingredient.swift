//
//  Ingredient.swift
//  Bitely
//
//  Created by Thomas Grega on 12/8/25.
//

import Foundation
import SwiftData

@Model
class Ingredient: Hashable {
    @Attribute(.unique) var id: UUID
    var name: String
    var measurement: String

    init(id: UUID = UUID(), name: String, measurement: String) {
        self.id = id
        self.name = name
        self.measurement = measurement
    }
}

extension Ingredient: Equatable {
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.id == rhs.id
    }
}
