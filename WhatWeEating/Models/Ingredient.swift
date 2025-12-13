//
//  Ingredient.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/8/25.
//

import Foundation
import SwiftData

@Model
class Ingredient: Hashable {
    @Attribute(.unique) var id = UUID()
    var name: String
    var measurementRaw: String
    var measurementQty: Double?
    var measurementUnit: MeasurementUnit?
    var isParsed: Bool

    init(name: String, measurementRaw: String, measurementQty: Double? = nil, measurementUnit: MeasurementUnit? = nil, isParsed: Bool = false) {
        self.name = name
        self.measurementRaw = measurementRaw
        self.measurementQty = measurementQty
        self.measurementUnit = measurementUnit
        self.isParsed = isParsed
    }
}

enum MeasurementUnitCategory: String, CaseIterable, Codable {
    case volume = "Volume"
    case mass = "Mass"
    case count = "Count"
    case special = "Special"

    var units: [MeasurementUnit] {
        MeasurementUnit.allCases.filter { $0.category == self }
    }
}

enum MeasurementUnit: String, CaseIterable, Codable {
    // Volume
    case teaspoon
    case tablespoon
    case fluidOunce
    case cup
    case pint
    case quart
    case gallon
    case milliliter
    case liter

    // Mass
    case gram
    case kilogram
    case ounce
    case pound

    // Count
    case piece
    case clove
    case can
    case slice

    // Special
    case pinch
    case dash
    case handful
    case toTaste
    case none

    var category: MeasurementUnitCategory {
        switch self {
        // Volume
        case .teaspoon, .tablespoon, .fluidOunce, .cup, .pint, .quart, .gallon, .milliliter, .liter:
            return .volume

        // Mass
        case .gram, .kilogram, .ounce, .pound:
            return .mass

        // Count
        case .piece, .clove, .can, .slice:
            return .count

        // Special
        case .pinch, .dash, .handful, .toTaste, .none:
            return .special
        }
    }

    var displayName: String {
        switch self {
        // Volume
        case .teaspoon: "tsp"
        case .tablespoon: "tbsp"
        case .fluidOunce: "fl oz"
        case .cup: "cup"
        case .pint: "pt"
        case .quart: "qt"
        case .gallon: "gal"
        case .milliliter: "mL"
        case .liter: "L"

        // Mass
        case .gram: "g"
        case .kilogram: "kg"
        case .ounce: "oz"
        case .pound: "lb"

        // Count
        case .piece: "piece"
        case .clove: "clove"
        case .can: "can"
        case .slice: "slice"

        // Special
        case .pinch: "pinch"
        case .dash: "dash"
        case .handful: "handful"
        case .toTaste: "to taste"
        case .none: ""
        }
    }
}

extension Ingredient: Equatable {
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.id == rhs.id
    }
}
