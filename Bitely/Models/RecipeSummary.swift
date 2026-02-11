//
//  BackendRecipe.swift
//  Bitely
//
//  Created by Thomas Grega on 1/29/26.
//

import Foundation

struct RecipeSummary: Identifiable, Hashable {
    let id: String
    let remoteId: String?
    let name: String
    let category: FoodCategory
    let thumbnailUrl: String?
    let imageData: Data?
    let calories: Int?
    let totalCookTime: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name, category
        case thumbnailUrl = "thumbnail_url"
        case imageData = "image_data"
        case calories
        case totalCookTime = "total_cook_time"
    }
}
