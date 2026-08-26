import Kingfisher
import SwiftUI

/// The bare picture, without the thumbnail's radius, stroke or overlay: the detail screen
/// runs it full-bleed. The source order is `ThumbnailSource`'s, so there is one copy of it.
struct RecipeImageView: View {
    let recipe: Recipe

    var body: some View {
        switch ThumbnailSource(
            imageData: recipe.imageData,
            thumbnailURL: recipe.thumbnailURL,
            category: recipe.category
        ) {
        case .photo(let data):
            Image(uiImage: UIImage(data: data) ?? UIImage()).resizable()
        case .remote(let url):
            KFImage(url).resizable()
        case .categoryTint(let category):
            Image(category.rawValue.lowercased()).resizable()
        }
    }
}

#Preview {
    RecipeImageView(recipe: Recipe(name: "Lemonade", category: .other))
}
