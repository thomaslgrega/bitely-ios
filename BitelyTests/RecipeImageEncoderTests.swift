import Foundation
import Testing
import UIKit
@testable import Bitely

/// Noise rather than a flat fill, so JPEG cannot compress the fixture to nothing and the
/// ceiling tests measure something.
private func noisyImage(width: CGFloat, height: CGFloat) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        .image { context in
            var generator = SystemRandomNumberGenerator()
            let block: CGFloat = 4
            for x in stride(from: 0, to: width, by: block) {
                for y in stride(from: 0, to: height, by: block) {
                    UIColor(
                        red: .random(in: 0...1, using: &generator),
                        green: .random(in: 0...1, using: &generator),
                        blue: .random(in: 0...1, using: &generator),
                        alpha: 1
                    ).setFill()
                    context.fill(CGRect(x: x, y: y, width: block, height: block))
                }
            }
        }
}

private func pixelSize(of encoded: EncodedRecipeImage) throws -> CGSize {
    let decoded = try #require(UIImage(data: encoded.data))
    return CGSize(
        width: decoded.size.width * decoded.scale,
        height: decoded.size.height * decoded.scale
    )
}

@Suite("Recipe image encoder")
struct RecipeImageEncoderTests {

    @Test("A landscape photo comes down to 800 on its longest edge, holding its aspect ratio")
    func landscapeHoldsItsRatio() throws {
        let encoded = try #require(RecipeImageEncoder.encode(noisyImage(width: 1600, height: 1200)))

        #expect(try pixelSize(of: encoded) == CGSize(width: 800, height: 600))
    }

    @Test("A portrait photo comes down to 800 on its longest edge, holding its aspect ratio")
    func portraitHoldsItsRatio() throws {
        let encoded = try #require(RecipeImageEncoder.encode(noisyImage(width: 1200, height: 1600)))

        #expect(try pixelSize(of: encoded) == CGSize(width: 600, height: 800))
    }

    @Test("A photo already smaller than the longest edge is left at its own size")
    func smallPhotoIsNotUpscaled() throws {
        let encoded = try #require(RecipeImageEncoder.encode(noisyImage(width: 400, height: 300)))

        #expect(try pixelSize(of: encoded) == CGSize(width: 400, height: 300))
    }

    @Test("The output declares the one content type the presign signs")
    func declaresJPEG() throws {
        let encoded = try #require(RecipeImageEncoder.encode(noisyImage(width: 900, height: 900)))

        #expect(encoded.contentType == "image/jpeg")
        #expect(encoded.contentLength == encoded.data.count)
    }

    @Test("The output fits under the ceiling")
    func fitsUnderTheCeiling() throws {
        let encoded = try #require(RecipeImageEncoder.encode(noisyImage(width: 2400, height: 1800)))

        #expect(encoded.contentLength <= RecipeImageEncoder.ceiling)
    }

    /// Stepping the quality down is only visible against a ceiling nothing can meet, and the
    /// answer there is the smallest attempt rather than nothing at all.
    @Test("A ceiling no quality can meet still answers bytes, at the lowest quality")
    func anUnmeetableCeilingStillAnswersBytes() throws {
        let image = noisyImage(width: 1600, height: 1200)
        let squeezed = try #require(RecipeImageEncoder.encode(image, ceiling: 1))
        let roomy = try #require(RecipeImageEncoder.encode(image))

        #expect(squeezed.contentLength > 1)
        #expect(squeezed.contentLength < roomy.contentLength)
    }
}

@Suite("Bytes already on disk")
struct ConformingImageTests {

    @Test("Bytes within the contract are handed back as they are")
    func conformingBytesArePassedThrough() throws {
        let stored = try #require(noisyImage(width: 400, height: 300).jpegData(compressionQuality: 0.8))

        let conforming = try #require(RecipeImageEncoder.conforming(stored))

        #expect(conforming.data == stored)
    }

    @Test("A full-resolution photo stored before the encoder existed is re-encoded")
    func oversizedBytesAreReEncoded() throws {
        let legacy = try #require(noisyImage(width: 2400, height: 1800).jpegData(compressionQuality: 0.8))

        let conforming = try #require(RecipeImageEncoder.conforming(legacy))

        #expect(try pixelSize(of: conforming) == CGSize(width: 800, height: 600))
        #expect(conforming.contentLength <= RecipeImageEncoder.ceiling)
    }

    /// Bytes that decode to nothing are not a photo, which is what `RecipeThumbnail` already
    /// makes of them.
    @Test("Bytes that are not an image answer nothing")
    func undecodableBytesAnswerNothing() {
        #expect(RecipeImageEncoder.conforming(Data(repeating: 0xFF, count: 512)) == nil)
    }
}
