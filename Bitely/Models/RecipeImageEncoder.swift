import UIKit

/// A Recipe's photo as the presign describes it: bytes, a declared type and a length.
struct EncodedRecipeImage: Equatable {
    let data: Data

    /// One exact string, because it is signed: R2 answers `image/jpg` with a 403.
    let contentType = "image/jpeg"

    var contentLength: Int { data.count }
}

/// Turns a picked photo into the bytes a share uploads. Pure over `UIImage`, so it is
/// testable with no picker and no network.
///
/// It runs when a photo is picked rather than when one is shared, so a Recipe never holds a
/// multi-megabyte blob in SwiftData — ADR-0002.
enum RecipeImageEncoder {
    /// One image serves both the card and the hero — `bitelyapi` ADR-0006.
    static let longestEdge: CGFloat = 800

    /// Well under the API's 5MB gate, which is a `HEAD` *after* the upload: oversized bytes
    /// are transferred and billed before being refused.
    static let ceiling = 1_000_000

    private static let qualities: [CGFloat] = [0.8, 0.6, 0.45, 0.3]

    /// Answers the lowest-quality attempt when no quality fits, because refusing to share
    /// over a ceiling the user cannot act on is worse than letting the API's gate answer.
    static func encode(_ image: UIImage, ceiling: Int = ceiling) -> EncodedRecipeImage? {
        let scaled = downscaled(image)
        var encoded: Data?
        for quality in qualities {
            encoded = scaled.jpegData(compressionQuality: quality)
            if let encoded, encoded.count <= ceiling { break }
        }
        return encoded.map(EncodedRecipeImage.init)
    }

    /// Renders at scale 1 whatever the source's scale, so the JPEG's pixels are the size
    /// this asked for. The ratio is capped at 1: a photo smaller than the edge is left alone.
    private static func downscaled(_ image: UIImage) -> UIImage {
        let size = image.size
        let ratio = min(1, longestEdge / max(size.width, size.height))
        let target = CGSize(
            width: (size.width * ratio).rounded(),
            height: (size.height * ratio).rounded()
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
