//
//  MealPlanDay.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/13/25.
//

import Foundation
import SwiftData

enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: Self { self }
}

@Model
class MealPlanDay {
    @Attribute(.unique) var dayKey: String

    @Relationship var breakfast: [Recipe] = []
    @Relationship var lunch: [Recipe] = []
    @Relationship var dinner: [Recipe] = []
    @Relationship var snack: [Recipe] = []

    init(dayKey: String) {
        self.dayKey = dayKey
    }

    subscript(mealType: MealType) -> [Recipe] {
        get {
            switch mealType {
            case .breakfast:
                return breakfast
            case .lunch:
                return lunch
            case .dinner:
                return dinner
            case .snack:
                return snack
            }
        }

        set {
            switch mealType {
            case .breakfast:
                breakfast = newValue
            case .lunch:
                lunch = newValue
            case .dinner:
                dinner = newValue
            case .snack:
                snack = newValue
            }
        }
    }
}
