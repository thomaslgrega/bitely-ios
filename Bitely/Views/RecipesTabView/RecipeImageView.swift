import Kingfisher
import SwiftUI

/// The bare picture, without the thumbnail's radius, stroke or overlay: the detail screen
/// runs it full-bleed. The source order is `RecipeImageSource`'s, so there is one copy of it.
struct RecipeImageView: View {
    let recipe: Recipe

    var body: some View {
        switch RecipeImageSource(
            imageData: recipe.imageData,
            imageURL: recipe.imageURL,
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
