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
    var measurement: String

    init(name: String, measurement: String) {
        self.name = name
        self.measurement = measurement
    }
}

extension Ingredient: Equatable {
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.id == rhs.id
    }
}


// Below is not in use after simplifying Ingredient Model. Was used to parse user input to be used for shopping list.
// Keeping for now because I may bring the feature back.

/*

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

    var aliases: [String] {
        switch self {
        // Volume
        case .teaspoon: ["tsp", "t", "teaspoon", "teaspoons"]
        case .tablespoon: ["tbsp", "T", "tablespoon", "tablespoons", "tbs"]
        case .fluidOunce: ["fl oz", "fluid ounce", "fluid ounces", "floz", "fl. oz"]
        case .cup: ["cup", "cups", "c"]
        case .pint: ["pint", "pints", "pt"]
        case .quart: ["quart", "quarts", "qt"]
        case .gallon: ["gallon", "gallons", "gal"]
        case .milliliter: ["ml", "milliliter", "milliliters", "millilitre", "millilitres"]
        case .liter: ["l", "liter", "liters", "litre", "litres"]

        // Mass
        case .gram: ["g", "gram", "grams"]
        case .kilogram: ["kg", "kilogram", "kilograms"]
        case .ounce: ["oz", "ounce", "ounces"]
        case .pound: ["lb", "lbs", "pound", "pounds"]

        // Count
        case .piece: ["piece", "pieces", "whole"]
        case .clove: ["clove", "cloves"]
        case .can: ["can", "cans", "tin", "tins"]
        case .slice: ["slice", "slices"]

        // Special
        case .pinch: ["pinch", "pinches"]
        case .dash: ["dash", "dashes"]
        case .handful: ["handful", "handfuls"]
        case .toTaste: ["to taste", "taste"]
        case .none: [""]
        }
    }
}

struct ParsedMeasurement {
    var quantity: Double?
    var unit: MeasurementUnit
    var ingredient: String
    var isParsed: Bool

    var displayString: String {
        guard isParsed, let qty = quantity else {
            return ""
        }

        let qtyString = qty.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", qty)
            : String(qty)

        if unit == .none {
            return qtyString
        }

        return "\(qtyString) \(unit.displayName)"
    }
}

class IngredientParser {
    private static let fractionMap: [String: Double] = [
        "1/2": 0.5,
        "1/3": 0.33,
        "2/3": 0.67,
        "1/4": 0.25,
        "3/4": 0.75,
        "1/8": 0.125,
        "3/8": 0.375,
        "5/8": 0.625,
        "7/8": 0.875,
        "⅛": 0.125,
        "¼": 0.25,
        "⅜": 0.375,
        "½": 0.5,
        "⅝": 0.625,
        "¾": 0.75,
        "⅞": 0.875,
        "⅓": 0.33,
        "⅔": 0.67
    ]

    static func parse(_ rawMeasurement: String, ingredient: String) -> ParsedMeasurement {
        var cleaned = rawMeasurement.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        cleaned = separateNumberFromUnit(cleaned)

        if cleaned.isEmpty || cleaned.contains("to taste") || cleaned.contains("taste") {
            return ParsedMeasurement(quantity: nil, unit: .none, ingredient: ingredient, isParsed: false)
        }

        let tokens = cleaned.split(separator: " ").map(String.init)

        guard !tokens.isEmpty else {
            return ParsedMeasurement(quantity: nil, unit: .none, ingredient: ingredient, isParsed: false)
        }

        var quantity: Double?
        var unit: MeasurementUnit = .none
        var currentIndex = 0

        if let firstQty = parseQuantity(tokens[currentIndex]) {
            quantity = firstQty
            currentIndex += 1

            if currentIndex < tokens.count, let fraction = parseFraction(tokens[currentIndex]) {
                quantity = (quantity ?? 0) + fraction
                currentIndex += 1
            }
        } else if let fraction = parseFraction(tokens[currentIndex]) {
            quantity = fraction
            currentIndex += 1
        }

        if currentIndex < tokens.count {
            let potentialUnit = tokens[currentIndex]
            if let foundUnit = findUnit(potentialUnit) {
                unit = foundUnit
                currentIndex += 1
            }
        }

        let ingredientName = Array(tokens[currentIndex...]).joined(separator: " ")

        let isParsed = quantity != nil || unit != .none

        return ParsedMeasurement(
            quantity: quantity,
            unit: unit,
            ingredient: ingredientName.isEmpty ? ingredient : ingredientName,
            isParsed: isParsed
        )
    }

    private static func separateNumberFromUnit(_ text: String) -> String {
        let pattern = "(\\d+(?:[./]\\d+)?(?:\\.\\d+)?)([a-z]+)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }

        let range = NSRange(text.startIndex..., in: text)
        let result = regex.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: "$1 $2"
        )

        return result
    }

    private static func parseQuantity(_ token: String) -> Double? {
        if let number = Double(token) {
            return number
        }

        return parseFraction(token)
    }

    private static func parseFraction(_ token: String) -> Double? {
        if let fraction = fractionMap[token] {
            return fraction
        }

        let parts = token.split(separator: "/")
        if parts.count == 2,
           let numerator = Double(parts[0]),
           let denominator = Double(parts[1]),
           denominator != 0 {
            return numerator / denominator
        }

        return nil
    }

    private static func findUnit(_ token: String) -> MeasurementUnit? {
        let cleaned = token.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".,"))

        for unit in MeasurementUnit.allCases {
            if unit.aliases.contains(where: { $0.lowercased() == cleaned }) {
                return unit
            }
        }

        return nil
    }
}

*/
