//
//  File.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 5/20/25.
//

import Foundation

struct Response: Codable {
    var meals: [Recipe]
}

struct Recipe: Codable, Identifiable, Hashable {
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
