import Kingfisher
import SwiftUI

/// Which of a Recipe's three picture sources a thumbnail draws, resolved before any view
/// exists so the order is exercised directly. Same order `RecipeImageView` has always used.
enum ThumbnailSource: Equatable {
    case photo(Data)
    case remote(URL)
    case categoryTint(FoodCategory)

    init(imageData: Data?, thumbnailURL: String?, category: FoodCategory) {
        // Decoding here rather than in the view keeps data that is not an image out of the
        // `photo` case entirely, so a corrupt blob falls through to the next source.
        if let imageData, UIImage(data: imageData) != nil {
            self = .photo(imageData)
        } else if let url = Self.fetchableURL(thumbnailURL) {
            self = .remote(url)
        } else {
            self = .categoryTint(category)
        }
    }

    /// A stored string only counts as a source if it can actually be fetched: the corpus
    /// carries empty and relative thumbnail fields, and both of those still parse.
    private static func fetchableURL(_ string: String?) -> URL? {
        guard let string, let url = URL(string: string.trimmingCharacters(in: .whitespaces)),
              url.scheme != nil, url.host()?.isEmpty == false
        else { return nil }
        return url
    }
}

/// Photo and tint share a radius, an inset stroke and a warm overlay, so a grid mixing
/// the two reads as one set rather than as half-loaded — design-system.md, RecipeThumbnail.
struct RecipeThumbnail: View {
    let source: ThumbnailSource
    let cornerRadius: CGFloat

    init(source: ThumbnailSource, cornerRadius: CGFloat = Radius.card) {
        self.source = source
        self.cornerRadius = cornerRadius
    }

    init(
        imageData: Data?,
        thumbnailURL: String?,
        category: FoodCategory,
        cornerRadius: CGFloat = Radius.card
    ) {
        self.init(
            source: ThumbnailSource(imageData: imageData, thumbnailURL: thumbnailURL, category: category),
            cornerRadius: cornerRadius
        )
    }

    var body: some View {
        picture
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.border, lineWidth: 1))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @ViewBuilder
    private var picture: some View {
        switch source {
        case .photo(let data):
            warmed(Image(uiImage: UIImage(data: data) ?? UIImage()).resizable())
        case .remote(let url):
            warmed(KFImage(url).resizable())
        case .categoryTint(let category):
            categoryIcon(on: category)
        }
    }

    private func warmed(_ photo: some View) -> some View {
        photo
            .aspectRatio(contentMode: .fill)
            .overlay(Color.surface.opacity(0.12))
    }

    private func categoryIcon(on category: FoodCategory) -> some View {
        GeometryReader { proxy in
            category.tint.overlay {
                Image(category.rawValue.lowercased())
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(proxy.size.width, proxy.size.height) * 0.58)
            }
        }
    }
}

#Preview("Category tints") {
    HStack(spacing: Spacing.l) {
        RecipeThumbnail(imageData: nil, thumbnailURL: nil, category: .seafood)
        RecipeThumbnail(imageData: nil, thumbnailURL: nil, category: .dessert)
    }
    .frame(height: 160)
    .padding()
    .background(Color.surface)
}
