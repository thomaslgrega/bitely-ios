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
    var strMealThumb: String
    var strIngredient1: String?
    var strIngredient2: String?
    var strIngredient3: String?
    var strIngredient4: String?
    var strIngredient5: String?
    var strIngredient6: String?
    var strIngredient7: String?
    var strIngredient8: String?
    var strIngredient9: String?
    var strIngredient10: String?
    var strIngredient11: String?
    var strIngredient12: String?
    var strIngredient13: String?
    var strIngredient14: String?
    var strIngredient15: String?
    var strIngredient16: String?
    var strIngredient17: String?
    var strIngredient18: String?
    var strIngredient19: String?
    var strIngredient20: String?
    var strMeasure1: String?
    var strMeasure2: String?
    var strMeasure3: String?
    var strMeasure4: String?
    var strMeasure5: String?
    var strMeasure6: String?
    var strMeasure7: String?
    var strMeasure8: String?
    var strMeasure9: String?
    var strMeasure10: String?
    var strMeasure11: String?
    var strMeasure12: String?
    var strMeasure13: String?
    var strMeasure14: String?
    var strMeasure15: String?
    var strMeasure16: String?
    var strMeasure17: String?
    var strMeasure18: String?
    var strMeasure19: String?
    var strMeasure20: String?

    init(id: String, strMeal: String, strCategory: String? = nil, strInstructions: String? = nil, strMealThumb: String, strIngredient1: String? = nil, strIngredient2: String? = nil, strIngredient3: String? = nil, strIngredient4: String? = nil, strIngredient5: String? = nil, strIngredient6: String? = nil, strIngredient7: String? = nil, strIngredient8: String? = nil, strIngredient9: String? = nil, strIngredient10: String? = nil, strIngredient11: String? = nil, strIngredient12: String? = nil, strIngredient13: String? = nil, strIngredient14: String? = nil, strIngredient15: String? = nil, strIngredient16: String? = nil, strIngredient17: String? = nil, strIngredient18: String? = nil, strIngredient19: String? = nil, strIngredient20: String? = nil, strMeasure1: String? = nil, strMeasure2: String? = nil, strMeasure3: String? = nil, strMeasure4: String? = nil, strMeasure5: String? = nil, strMeasure6: String? = nil, strMeasure7: String? = nil, strMeasure8: String? = nil, strMeasure9: String? = nil, strMeasure10: String? = nil, strMeasure11: String? = nil, strMeasure12: String? = nil, strMeasure13: String? = nil, strMeasure14: String? = nil, strMeasure15: String? = nil, strMeasure16: String? = nil, strMeasure17: String? = nil, strMeasure18: String? = nil, strMeasure19: String? = nil, strMeasure20: String? = nil) {
        self.id = id
        self.strMeal = strMeal
        self.strCategory = strCategory
        self.strInstructions = strInstructions
        self.strMealThumb = strMealThumb
        self.strIngredient1 = strIngredient1
        self.strIngredient2 = strIngredient2
        self.strIngredient3 = strIngredient3
        self.strIngredient4 = strIngredient4
        self.strIngredient5 = strIngredient5
        self.strIngredient6 = strIngredient6
        self.strIngredient7 = strIngredient7
        self.strIngredient8 = strIngredient8
        self.strIngredient9 = strIngredient9
        self.strIngredient10 = strIngredient10
        self.strIngredient11 = strIngredient11
        self.strIngredient12 = strIngredient12
        self.strIngredient13 = strIngredient13
        self.strIngredient14 = strIngredient14
        self.strIngredient15 = strIngredient15
        self.strIngredient16 = strIngredient16
        self.strIngredient17 = strIngredient17
        self.strIngredient18 = strIngredient18
        self.strIngredient19 = strIngredient19
        self.strIngredient20 = strIngredient20
        self.strMeasure1 = strMeasure1
        self.strMeasure2 = strMeasure2
        self.strMeasure3 = strMeasure3
        self.strMeasure4 = strMeasure4
        self.strMeasure5 = strMeasure5
        self.strMeasure6 = strMeasure6
        self.strMeasure7 = strMeasure7
        self.strMeasure8 = strMeasure8
        self.strMeasure9 = strMeasure9
        self.strMeasure10 = strMeasure10
        self.strMeasure11 = strMeasure11
        self.strMeasure12 = strMeasure12
        self.strMeasure13 = strMeasure13
        self.strMeasure14 = strMeasure14
        self.strMeasure15 = strMeasure15
        self.strMeasure16 = strMeasure16
        self.strMeasure17 = strMeasure17
        self.strMeasure18 = strMeasure18
        self.strMeasure19 = strMeasure19
        self.strMeasure20 = strMeasure20
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        strMeal = try container.decode(String.self, forKey: .strMeal)
        strCategory = try container.decodeIfPresent(String.self, forKey: .strCategory)
        strInstructions = try container.decodeIfPresent(String.self, forKey: .strInstructions)
        strMealThumb = try container.decode(String.self, forKey: .strMealThumb)
        strIngredient1 = try container.decodeIfPresent(String.self, forKey: .strIngredient1)
        strIngredient2 = try container.decodeIfPresent(String.self, forKey: .strIngredient2)
        strIngredient3 = try container.decodeIfPresent(String.self, forKey: .strIngredient3)
        strIngredient4 = try container.decodeIfPresent(String.self, forKey: .strIngredient4)
        strIngredient5 = try container.decodeIfPresent(String.self, forKey: .strIngredient5)
        strIngredient6 = try container.decodeIfPresent(String.self, forKey: .strIngredient6)
        strIngredient7 = try container.decodeIfPresent(String.self, forKey: .strIngredient7)
        strIngredient8 = try container.decodeIfPresent(String.self, forKey: .strIngredient8)
        strIngredient9 = try container.decodeIfPresent(String.self, forKey: .strIngredient9)
        strIngredient10 = try container.decodeIfPresent(String.self, forKey: .strIngredient10)
        strIngredient11 = try container.decodeIfPresent(String.self, forKey: .strIngredient11)
        strIngredient12 = try container.decodeIfPresent(String.self, forKey: .strIngredient12)
        strIngredient13 = try container.decodeIfPresent(String.self, forKey: .strIngredient13)
        strIngredient14 = try container.decodeIfPresent(String.self, forKey: .strIngredient14)
        strIngredient15 = try container.decodeIfPresent(String.self, forKey: .strIngredient15)
        strIngredient16 = try container.decodeIfPresent(String.self, forKey: .strIngredient16)
        strIngredient17 = try container.decodeIfPresent(String.self, forKey: .strIngredient17)
        strIngredient18 = try container.decodeIfPresent(String.self, forKey: .strIngredient18)
        strIngredient19 = try container.decodeIfPresent(String.self, forKey: .strIngredient19)
        strIngredient20 = try container.decodeIfPresent(String.self, forKey: .strIngredient20)
        strMeasure1 = try container.decodeIfPresent(String.self, forKey: .strMeasure1)
        strMeasure2 = try container.decodeIfPresent(String.self, forKey: .strMeasure2)
        strMeasure3 = try container.decodeIfPresent(String.self, forKey: .strMeasure3)
        strMeasure4 = try container.decodeIfPresent(String.self, forKey: .strMeasure4)
        strMeasure5 = try container.decodeIfPresent(String.self, forKey: .strMeasure5)
        strMeasure6 = try container.decodeIfPresent(String.self, forKey: .strMeasure6)
        strMeasure7 = try container.decodeIfPresent(String.self, forKey: .strMeasure7)
        strMeasure8 = try container.decodeIfPresent(String.self, forKey: .strMeasure8)
        strMeasure9 = try container.decodeIfPresent(String.self, forKey: .strMeasure9)
        strMeasure10 = try container.decodeIfPresent(String.self, forKey: .strMeasure10)
        strMeasure11 = try container.decodeIfPresent(String.self, forKey: .strMeasure11)
        strMeasure12 = try container.decodeIfPresent(String.self, forKey: .strMeasure12)
        strMeasure13 = try container.decodeIfPresent(String.self, forKey: .strMeasure13)
        strMeasure14 = try container.decodeIfPresent(String.self, forKey: .strMeasure14)
        strMeasure15 = try container.decodeIfPresent(String.self, forKey: .strMeasure15)
        strMeasure16 = try container.decodeIfPresent(String.self, forKey: .strMeasure16)
        strMeasure17 = try container.decodeIfPresent(String.self, forKey: .strMeasure17)
        strMeasure18 = try container.decodeIfPresent(String.self, forKey: .strMeasure18)
        strMeasure19 = try container.decodeIfPresent(String.self, forKey: .strMeasure19)
        strMeasure20 = try container.decodeIfPresent(String.self, forKey: .strMeasure20)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(strMeal, forKey: .strMeal)
        try container.encode(strCategory, forKey: .strCategory)
        try container.encode(strInstructions, forKey: .strInstructions)
        try container.encode(strMealThumb, forKey: .strMealThumb)
        try container.encode(strIngredient1, forKey: .strIngredient1)
        try container.encode(strIngredient2, forKey: .strIngredient2)
        try container.encode(strIngredient3, forKey: .strIngredient3)
        try container.encode(strIngredient4, forKey: .strIngredient4)
        try container.encode(strIngredient5, forKey: .strIngredient5)
        try container.encode(strIngredient6, forKey: .strIngredient6)
        try container.encode(strIngredient7, forKey: .strIngredient7)
        try container.encode(strIngredient8, forKey: .strIngredient8)
        try container.encode(strIngredient9, forKey: .strIngredient9)
        try container.encode(strIngredient10, forKey: .strIngredient10)
        try container.encode(strIngredient11, forKey: .strIngredient11)
        try container.encode(strIngredient12, forKey: .strIngredient12)
        try container.encode(strIngredient13, forKey: .strIngredient13)
        try container.encode(strIngredient14, forKey: .strIngredient14)
        try container.encode(strIngredient15, forKey: .strIngredient15)
        try container.encode(strIngredient16, forKey: .strIngredient16)
        try container.encode(strIngredient17, forKey: .strIngredient17)
        try container.encode(strIngredient18, forKey: .strIngredient18)
        try container.encode(strIngredient19, forKey: .strIngredient19)
        try container.encode(strIngredient20, forKey: .strIngredient20)
        try container.encode(strMeasure1, forKey: .strMeasure1)
        try container.encode(strMeasure2, forKey: .strMeasure2)
        try container.encode(strMeasure3, forKey: .strMeasure3)
        try container.encode(strMeasure4, forKey: .strMeasure4)
        try container.encode(strMeasure5, forKey: .strMeasure5)
        try container.encode(strMeasure6, forKey: .strMeasure6)
        try container.encode(strMeasure7, forKey: .strMeasure7)
        try container.encode(strMeasure8, forKey: .strMeasure8)
        try container.encode(strMeasure9, forKey: .strMeasure9)
        try container.encode(strMeasure10, forKey: .strMeasure10)
        try container.encode(strMeasure11, forKey: .strMeasure11)
        try container.encode(strMeasure12, forKey: .strMeasure12)
        try container.encode(strMeasure13, forKey: .strMeasure13)
        try container.encode(strMeasure14, forKey: .strMeasure14)
        try container.encode(strMeasure15, forKey: .strMeasure15)
        try container.encode(strMeasure16, forKey: .strMeasure16)
        try container.encode(strMeasure17, forKey: .strMeasure17)
        try container.encode(strMeasure18, forKey: .strMeasure18)
        try container.encode(strMeasure19, forKey: .strMeasure19)
        try container.encode(strMeasure20, forKey: .strMeasure20)
    }
}

extension Recipe {
    var ingredients: [String: String] {
        let ingredientNames = [
            strIngredient1, strIngredient2, strIngredient3, strIngredient4, strIngredient5,
            strIngredient6, strIngredient7, strIngredient8, strIngredient9, strIngredient10,
            strIngredient11, strIngredient12, strIngredient13, strIngredient14, strIngredient15,
            strIngredient16, strIngredient17, strIngredient18, strIngredient19, strIngredient20
        ]

        let measurements = [
            strMeasure1, strMeasure2, strMeasure3, strMeasure4, strMeasure5,
            strMeasure6, strMeasure7, strMeasure8, strMeasure9, strMeasure10,
            strMeasure11, strMeasure12, strMeasure13, strMeasure14, strMeasure15,
            strMeasure16, strMeasure17, strMeasure18, strMeasure19, strMeasure20
        ]

        var dict = [String: String]()

        for i in 0..<20 {
            guard let name = ingredientNames[i] else {
                break
            }

            guard let measurement = measurements[i] else {
                break
            }

            dict[name] = measurement
        }

        return dict
    }
}


//{
//    "idMeal": "52771",
//    "strMeal": "Spicy Arrabiata Penne",
//    "strMealAlternate": null,
//    "strCategory": "Vegetarian",
//    "strArea": "Italian",
//    "strInstructions": "Bring a large pot of water to a boil. Add kosher salt to the boiling water, then add the pasta. Cook according to the package instructions, about 9 minutes.\r\nIn a large skillet over medium-high heat, add the olive oil and heat until the oil starts to shimmer. Add the garlic and cook, stirring, until fragrant, 1 to 2 minutes. Add the chopped tomatoes, red chile flakes, Italian seasoning and salt and pepper to taste. Bring to a boil and cook for 5 minutes. Remove from the heat and add the chopped basil.\r\nDrain the pasta and add it to the sauce. Garnish with Parmigiano-Reggiano flakes and more basil and serve warm.",
//    "strMealThumb": "https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg",
//    "strTags": "Pasta,Curry",
//    "strYoutube": "https://www.youtube.com/watch?v=1IszT_guI08",
//    "strIngredient1": "penne rigate",
//    "strIngredient2": "olive oil",
//    "strIngredient3": "garlic",
//    "strIngredient4": "chopped tomatoes",
//    "strIngredient5": "red chilli flakes",
//    "strIngredient6": "italian seasoning",
//    "strIngredient7": "basil",
//    "strIngredient8": "Parmigiano-Reggiano",
//    "strIngredient9": "",
//    "strIngredient10": "",
//    "strIngredient11": "",
//    "strIngredient12": "",
//    "strIngredient13": "",
//    "strIngredient14": "",
//    "strIngredient15": "",
//    "strIngredient16": null,
//    "strIngredient17": null,
//    "strIngredient18": null,
//    "strIngredient19": null,
//    "strIngredient20": null,
//    "strMeasure1": "1 pound",
//    "strMeasure2": "1/4 cup",
//    "strMeasure3": "3 cloves",
//    "strMeasure4": "1 tin ",
//    "strMeasure5": "1/2 teaspoon",
//    "strMeasure6": "1/2 teaspoon",
//    "strMeasure7": "6 leaves",
//    "strMeasure8": "sprinkling",
//    "strMeasure9": "",
//    "strMeasure10": "",
//    "strMeasure11": "",
//    "strMeasure12": "",
//    "strMeasure13": "",
//    "strMeasure14": "",
//    "strMeasure15": "",
//    "strMeasure16": null,
//    "strMeasure17": null,
//    "strMeasure18": null,
//    "strMeasure19": null,
//    "strMeasure20": null,
//    "strSource": null,
//    "strImageSource": null,
//    "strCreativeCommonsConfirmed": null,
//    "dateModified": null
//}
