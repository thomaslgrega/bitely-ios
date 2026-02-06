//
//  RecipeImageView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 2/2/26.
//

import Kingfisher
import SwiftUI

struct RecipeImageView: View {
    let recipe: Recipe

    var body: some View {
        if let data = recipe.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
        } else if let urlString = recipe.thumbnailURL, let url = URL(string: urlString) {
            KFImage(url)
                .resizable()
        } else {
            Image(recipe.category.rawValue.lowercased())
                .resizable()
        }
    }
}

#Preview {
    RecipeImageView(recipe: Recipe(name: "Lemonade", category: .other))
}
