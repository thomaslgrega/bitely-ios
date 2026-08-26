import SwiftUI

/// Intrinsically sized — no reserved line count — because the name grows with Dynamic
/// Type and a fixed height clips it.
struct RecipeTile: View {
    let name: String
    let thumbnail: ThumbnailSource
    var cookTime: Int?
    var calories: Int?
    var saveButton: SaveButton?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            RecipeThumbnail(source: thumbnail)
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .topTrailing) { saveButton?.padding(Spacing.s) }

            Text(name)
                .textStyle(.cardTitle)
                .foregroundStyle(Color.contentPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if cookTime != nil || calories != nil {
                HStack(spacing: Spacing.m) {
                    MetaLabel.cookTime(minutes: cookTime)
                    MetaLabel.calories(calories)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension RecipeTile {
    init(recipe: RecipeSummary, saveButton: SaveButton? = nil) {
        self.init(
            name: recipe.name,
            thumbnail: ThumbnailSource(
                imageData: recipe.imageData,
                thumbnailURL: recipe.thumbnailUrl,
                category: recipe.category
            ),
            cookTime: recipe.totalCookTime,
            calories: recipe.calories,
            saveButton: saveButton
        )
    }
}

private struct RecipeTilePreview: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.l) {
            RecipeTile(
                name: "Slow-Braised Short Rib with Red Wine",
                thumbnail: .categoryTint(.beef),
                cookTime: 190,
                calories: 720,
                saveButton: SaveButton(isSaved: true, onSave: {}, onUnsave: {})
            )
            RecipeTile(name: "Shakshuka", thumbnail: .categoryTint(.breakfast), cookTime: 35)
        }
        .padding()
        .background(Color.surface)
    }
}

/// The pair of sizes intrinsic sizing exists for: at `.accessibility3` the names run to
/// several lines and neither tile may clip.
#Preview("Large", traits: .sizeThatFitsLayout) {
    RecipeTilePreview().dynamicTypeSize(.large)
}

#Preview("Accessibility 3", traits: .sizeThatFitsLayout) {
    RecipeTilePreview().dynamicTypeSize(.accessibility3)
}
