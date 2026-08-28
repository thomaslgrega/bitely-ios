import SwiftData
import SwiftUI

/// A grid tile that leads to its Recipe, with the heart beside the link rather than inside
/// it: the whole tile is already a link, and a button nested in another button does not
/// reliably take its own taps.
///
/// `held` comes from the grid's one query over the device's Recipes — a tile asking for
/// itself is a query per tile, and a grid draws up to fifty.
struct SavableRecipeTile: View {
    let recipe: RecipeSummaryDTO
    let held: HeldRecipes

    @Environment(Cookbook.self) private var cookbook
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: recipe) {
                RecipeTile(recipe: RecipeSummary(recipe))
            }
            .buttonStyle(.plain)

            if cookbook.offersSaving(of: recipe.id) {
                SaveButton(
                    isSaved: held.contains(recipe.id),
                    onSave: { Task { await cookbook.save(remoteId: recipe.id, into: modelContext) } },
                    onUnsave: {
                        guard let local = held.recipe(for: recipe.id) else { return }
                        cookbook.unsave(local, from: modelContext)
                    }
                )
                .padding(Spacing.s)
            }
        }
    }
}
