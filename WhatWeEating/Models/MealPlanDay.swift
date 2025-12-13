//
//  MealPlanDay.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/13/25.
//

import Foundation
import SwiftData

@Model
class MealPlanDay {
    @Attribute(.unique) var date: Date

    @Relationship(deleteRule: .nullify) var breakfast: [Recipe] = []
    @Relationship(deleteRule: .nullify) var lunch: [Recipe] = []
    @Relationship(deleteRule: .nullify) var dinner: [Recipe] = []
    @Relationship(deleteRule: .nullify) var snack: [Recipe] = []

    init(date: Date) {
        self.date = date
    }
}
