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

extension RecipeSummary {
    /// A corpus Recipe the device holds no copy of: its remote id is the only id it has,
    /// and its picture can only come from the URL the corpus carries.
    init(_ dto: RecipeSummaryDTO) {
        self.init(
            id: dto.id,
            remoteId: dto.id,
            name: dto.name,
            category: dto.category,
            thumbnailUrl: dto.thumbnailUrl,
            imageData: nil,
            calories: dto.calories,
            totalCookTime: dto.totalCookTime
        )
    }
}

extension RecipeSummary {
    /// A Recipe the device holds: it has a local id of its own, and a photo the user
    /// attached outranks whatever thumbnail the corpus carried.
    init(_ recipe: Recipe) {
        self.init(
            id: recipe.id.uuidString,
            remoteId: recipe.remoteId,
            name: recipe.name,
            category: recipe.category,
            thumbnailUrl: recipe.thumbnailURL,
            imageData: recipe.imageData,
            calories: recipe.calories,
            totalCookTime: recipe.totalCookTime
        )
    }
}
