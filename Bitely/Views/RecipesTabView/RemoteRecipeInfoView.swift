import SwiftData
import SwiftUI

struct RemoteRecipeInfoView: View {
    @Environment(RecipeService.self) private var recipeService
    @Environment(Cookbook.self) private var cookbook
    @Environment(\.modelContext) private var modelContext
    @Query private var savedRecipes: [Recipe]

    let recipeId: String
    let allowEdit: Bool

    /// What the API answered, kept so the save builds its copy from the Recipe in full
    /// rather than from the one on screen.
    @State private var detail: RecipeDetailDTO?
    @State private var recipe: Recipe?

    var savedRecipe: Recipe? { HeldRecipes(savedRecipes).recipe(for: recipeId) }

    var isSaved: Bool { savedRecipe != nil }

    var body: some View {
        Group {
            if let recipe {
                RecipeInfoContentView(
                    recipe: recipe,
                    allowEdit: allowEdit,
                    isSaved: isSaved,
                    onToggleBookmark: { isSaved ? deleteSavedCopy() : bookmarkRemoteRecipe() })
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.surface)
                    .task(id: recipeId) {
                        await load()
                    }
            }
        }
    }

    private func load() async {
        guard recipe == nil else { return }
        do {
            let dto = try await recipeService.getRecipeById(id: recipeId)
            detail = dto
            recipe = Recipe(dto)
        } catch {
            print("Error fetching recipe:", error)
        }
    }

    private func bookmarkRemoteRecipe() {
        guard let detail else { return }
        cookbook.save(detail, into: modelContext)
    }

    private func deleteSavedCopy() {
        guard let toDelete = savedRecipe else { return }
        cookbook.unsave(toDelete, from: modelContext)
    }
}

#Preview {
    RemoteRecipeInfoView(recipeId: "12345", allowEdit: false)
        .previewStores()
}
