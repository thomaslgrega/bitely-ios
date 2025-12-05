//
//  File.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/20/25.
//

import Foundation
import SwiftData

struct Response: Codable {
    var meals: [Recipe]
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

@Model
class Ingredient: Identifiable, Hashable {
    var id: String
    var name: String
    var measurementRaw: String
    var measurementQty: Double?
    var measurementUnit: MeasurementUnit?
    var isParsed: Bool

    init(id: String = UUID().uuidString, name: String, measurementRaw: String, measurementQty: Double? = nil, measurementUnit: MeasurementUnit? = nil, isParsed: Bool = false) {
        self.id = id
        self.name = name
        self.measurementRaw = measurementRaw
        self.measurementQty = measurementQty
        self.measurementUnit = measurementUnit
        self.isParsed = isParsed
    }
}

@Model
class Recipe: Codable, Identifiable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id = "idMeal"
        case strMeal, strCategory, strInstructions, strMealThumb
        case strIngredient1
        case strIngredient2
        case strIngredient3
        case strIngredient4
        case strIngredient5
        case strIngredient6
        case strIngredient7
        case strIngredient8
        case strIngredient9
        case strIngredient10
        case strIngredient11
        case strIngredient12
        case strIngredient13
        case strIngredient14
        case strIngredient15
        case strIngredient16
        case strIngredient17
        case strIngredient18
        case strIngredient19
        case strIngredient20
        case strMeasure1
        case strMeasure2
        case strMeasure3
        case strMeasure4
        case strMeasure5
        case strMeasure6
        case strMeasure7
        case strMeasure8
        case strMeasure9
        case strMeasure10
        case strMeasure11
        case strMeasure12
        case strMeasure13
        case strMeasure14
        case strMeasure15
        case strMeasure16
        case strMeasure17
        case strMeasure18
        case strMeasure19
        case strMeasure20
    }

    var id: String
    var strMeal: String
    var strCategory: String?
    var strInstructions: String?
    var strMealThumb: String?

    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]

    init(id: String, strMeal: String, strCategory: String? = nil, strInstructions: String? = nil, strMealThumb: String?, ingredients: [Ingredient] = []) {
        self.id = id
        self.strMeal = strMeal
        self.strCategory = strCategory
        self.strInstructions = strInstructions
        self.strMealThumb = strMealThumb
        self.ingredients = ingredients
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        strMeal = try container.decode(String.self, forKey: .strMeal)
        strCategory = try container.decodeIfPresent(String.self, forKey: .strCategory)
        strInstructions = try container.decodeIfPresent(String.self, forKey: .strInstructions)
        strMealThumb = try container.decodeIfPresent(String.self, forKey: .strMealThumb)

        var ingredients = [Ingredient]()
        for i in 1...20 {
            let nameKey = CodingKeys(stringValue: "strIngredient\(i)")!
            let measurementKey = CodingKeys(stringValue: "strMeasure\(i)")!

            let name = try container.decodeIfPresent(String.self, forKey: nameKey) ?? ""
            let measurement = try container.decodeIfPresent(String.self, forKey: measurementKey) ?? ""

            if name == "" { break }

            // TODO: Add parsing measurements from TheMealDB into measurementQty and measurementUnit
            ingredients.append(Ingredient(name: name, measurementRaw: measurement))
        }

        self.ingredients = ingredients
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(strMeal, forKey: .strMeal)
        try container.encode(strCategory, forKey: .strCategory)
        try container.encode(strInstructions, forKey: .strInstructions)
        try container.encode(strMealThumb, forKey: .strMealThumb)
    }
}
