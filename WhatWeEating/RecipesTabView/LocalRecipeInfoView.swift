//
//  LocalRecipeInfoView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 2/2/26.
//

import SwiftUI

struct LocalRecipeInfoView: View {
    @Environment(\.modelContext) private var modelContext

    let recipe: Recipe
    let allowEdit: Bool

    var body: some View {
        RecipeInfoContentView(
            recipe: recipe,
            allowEdit: allowEdit,
            isSaved: true,
            onToggleBookmark: { modelContext.delete(recipe) }
        )
    }
}

#Preview {
    LocalRecipeInfoView(recipe: Recipe(name: "Lemonade", category: .miscellaneous), allowEdit: true)
}
