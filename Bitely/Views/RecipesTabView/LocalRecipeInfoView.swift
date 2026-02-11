//
//  LocalRecipeInfoView.swift
//  Bitely
//
//  Created by Thomas Grega on 2/2/26.
//

import SwiftData
import SwiftUI

struct LocalRecipeInfoView: View {
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
                modelContext.delete(recipe)
                dismiss()
            }
        )
    }
}

#Preview {
    LocalRecipeInfoView(recipe: Recipe(name: "Lemonade", category: .other), allowEdit: true)
}
