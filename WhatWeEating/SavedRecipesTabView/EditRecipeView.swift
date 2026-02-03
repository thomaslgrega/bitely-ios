//
//  AddRecipeView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/1/25.
//

import PhotosUI
import SwiftUI

struct EditRecipeView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var recipe: Recipe

    @State private var showRequiredNameError = false
    @State private var showRequiredCategoryError = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Recipe name")
                            .foregroundStyle(Color.secondary700)

                        if showRequiredNameError {
                            Spacer()
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                Text("This field is required")
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .font(.subheadline)

                    TextField("Recipe Name", text: $recipe.name)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(showRequiredNameError ? .red : .secondary200, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Image")
                        .foregroundStyle(Color.secondary700)
                        .font(.subheadline)

                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        if let image = selectedImage {
                            ZStack(alignment: .bottomLeading) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                Button {
                                    selectedPhotoItem = nil
                                    selectedImage = nil
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Color.secondary100)
                                        .frame(width: 50, height: 50)
                                        .background(Color.primaryMain)
                                        .clipShape(Circle())
                                        .padding()
                                }
                            }
                        } else {
                            VStack(alignment: .center, spacing: 12) {
                                Image(systemName: "photo")
                                Text("Add Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary200, lineWidth: 1)
                    )
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImage = image
                            }
                        }
                    }
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Category")
                            .foregroundStyle(Color.secondary700)

                        if showRequiredCategoryError {
                            Spacer()
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                Text("This field is required")
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .font(.subheadline)

                    Picker("Category", selection: $recipe.category) {
                        Text("Select a category")
                            .tag(nil as FoodCategory?)
                            .disabled(true)

                        ForEach(FoodCategory.allCases, id: \.self) { category in
                            Text(category.rawValue)
                                .tag(Optional(category))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(showRequiredCategoryError ? .red : .secondary200, lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Calories")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary700)

                            TextField("Calories", text: .optionalInt($recipe.calories))
                                .keyboardType(.numberPad)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                                .textFieldStyle(.roundedBorder)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.secondary200, lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading) {
                            Text("Cooking time (in min)")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary700)

                            TextField("Minutes", text: .optionalInt($recipe.totalCookTime))
                                .keyboardType(.numberPad)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                                .textFieldStyle(.roundedBorder)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.secondary200, lineWidth: 1)
                                )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary700)

                    ForEach($recipe.ingredients) { $ingredient in
                        IngredientRowView(ingredient: $ingredient) {
                            removeIngredient(ingredient)
                        }
                        .padding()
                        .frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary200, lineWidth: 1)
                        )
                    }

                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(Color.primaryMain)
                        Button("Add an ingredient", action: addNewIngredient)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary700)

                    TextField("Instructions", text: $recipe.instructions.orEmpty(), axis: .vertical)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary100))
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary200, lineWidth: 1)
                        )
                        .lineLimit(3...)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                // TODO: Toolbar and alert for discard (cancel or discard)
                Button {
                    saveRecipe()
                } label: {
                    Text("Save")
                }
            }
            .onAppear {
                if let data = recipe.imageData, let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }

    func addNewIngredient() {
        recipe.ingredients.append(Ingredient(name: "", measurement: ""))
    }

    func removeIngredient(_ ingredient: Ingredient) {
        if let idx = recipe.ingredients.firstIndex(where: { $0.id == ingredient.id }) {
            recipe.ingredients.remove(at: idx)
        }
    }

    func saveRecipe() {
        showRequiredNameError = recipe.name == ""

        if showRequiredNameError {
            return
        }

        recipe.ingredients = recipe.ingredients.filter { $0.name.trimmingCharacters(in: .whitespaces) != "" }

        if let jpegData = selectedImage?.jpegData(compressionQuality: 0.8) {
            recipe.imageData = jpegData
        } else {
            recipe.imageData = nil
        }

        if recipe.modelContext == nil {
            modelContext.insert(recipe)
        }
        dismiss()
    }
}

#Preview {
    let ingredient1 = Ingredient(name: "Tomato", measurement: "2")
    let ingredient2 = Ingredient(name: "Sugar", measurement: "200g")

    NavigationStack {
        EditRecipeView(recipe: Recipe(name: "", category: .beef, thumbnailURL: "", ingredients: [ingredient1, ingredient2], calories: nil, totalCookTime: nil))
    }
}
