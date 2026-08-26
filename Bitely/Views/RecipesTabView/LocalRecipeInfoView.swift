import SwiftData
import SwiftUI

struct LocalRecipeInfoView: View {
    @Environment(Cookbook.self) private var cookbook
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var savedRecipes: [Recipe]

    let recipe: Recipe
    let allowEdit: Bool

    var isSaved: Bool {
        savedRecipes.contains(where: { $0.id == recipe.id })
    }

    var body: some View {
        RecipeInfoContentView(
            recipe: recipe,
            allowEdit: allowEdit,
            isSaved: isSaved,
            onToggleBookmark: {
                cookbook.unsave(recipe, from: modelContext)
                dismiss()
            }
        )
    }
}

#Preview {
    LocalRecipeInfoView(recipe: Recipe(name: "Lemonade", category: .other), allowEdit: true)
        .previewStores()
}
