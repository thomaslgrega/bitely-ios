import SwiftUI

/// What a Match says on the list: its Coverage as the integer pair the matcher keeps, and
/// the Missing Ingredients spelled out. An incomplete Match is the point of the feature, so
/// it says what a trip to the shop would cost.
struct CoverageSummary: Equatable {
    let match: RecipeMatch

    var coverage: String { "You have \(match.matchedCount) of \(match.totalCount) ingredients" }

    var isComplete: Bool { match.missingIngredients.isEmpty }

    /// Nil over a Match the Pantry covers entirely, which says so instead of showing an
    /// empty list.
    var missing: String? {
        isComplete ? nil : "Missing: \(match.missingIngredients.joined(separator: ", "))"
    }
}

struct PantryMatchRow: View {
    let match: RecipeMatch

    private var summary: CoverageSummary { CoverageSummary(match: match) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(match.recipeName)
                .textStyle(.cardTitle)
                .foregroundStyle(Color.contentPrimary)
                .multilineTextAlignment(.leading)

            Text(summary.coverage)
                .textStyle(.meta)
                .foregroundStyle(Color.contentSecondary)

            if let missing = summary.missing {
                Text(missing)
                    .textStyle(.meta)
                    .foregroundStyle(Color.contentSecondary)
                    .multilineTextAlignment(.leading)
            } else {
                Text("You have everything")
                    .textStyle(.meta)
                    .foregroundStyle(Color.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.surfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Color.border, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: Spacing.m) {
        PantryMatchRow(match: RecipeMatch(
            recipeID: "1",
            recipeName: "Brown Butter Gnocchi",
            matchedCount: 3,
            totalCount: 5,
            missingIngredients: ["sage", "parmesan"]
        ))

        PantryMatchRow(match: RecipeMatch(
            recipeID: "2",
            recipeName: "Shakshuka",
            matchedCount: 4,
            totalCount: 4,
            missingIngredients: []
        ))
    }
    .padding()
    .background(Color.surface)
}
