import PhotosUI
import SwiftUI

/// Editing is local and available on every Recipe in the Cookbook, whoever authored it.
/// Adding salt to a Saved Recipe writes to the local copy and never reaches the API —
/// which is why gating sharing costs the user nothing. docs/design/app-flow.md, Cookbook.
struct EditRecipeView: View {
    @Environment(Cookbook.self) private var cookbook
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var recipe: Recipe

    @State private var showRequiredNameError = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                FormField(
                    label: "Recipe name",
                    error: showRequiredNameError ? FieldError.required : nil
                ) {
                    TextField("Recipe name", text: $recipe.name)
                        .textStyle(.body)
                }

                photo

                FormField(label: "Category") {
                    Picker("Category", selection: $recipe.category) {
                        ForEach(FoodCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .tint(Color.contentPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(alignment: .top, spacing: Spacing.m) {
                    FormField(label: "Calories") {
                        TextField("Calories", text: .optionalInt($recipe.calories))
                            .keyboardType(.numberPad)
                            .textStyle(.body)
                    }

                    FormField(label: "Cooking time (min)") {
                        TextField("Minutes", text: .optionalInt($recipe.totalCookTime))
                            .keyboardType(.numberPad)
                            .textStyle(.body)
                    }
                }

                ingredients

                FormField(label: "Instructions") {
                    TextField("Instructions", text: $recipe.instructions.orEmpty(), axis: .vertical)
                        .textStyle(.body)
                        .lineLimit(3...)
                }
            }
            .foregroundStyle(Color.contentPrimary)
            .padding(Spacing.xl)
        }
        .background(Color.surface)
        .toolbar {
            // TODO: Toolbar and alert for discard (cancel or discard)
            Button("Save", action: saveRecipe)
                .tint(Color.accent)
        }
        .onAppear {
            if let data = recipe.imageData, let image = UIImage(data: data) {
                selectedImage = image
            }
        }
    }

    private var photo: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Photo")
                .textStyle(.label)
                .foregroundStyle(Color.contentSecondary)

            // The picker wraps both branches, so tapping a photo already chosen replaces
            // it; the trash beside it is the only way to end up with none.
            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                } else {
                    VStack(spacing: Spacing.s) {
                        Image(systemName: "photo")
                            .font(.system(size: SymbolSize.emptyState, weight: .light))
                        Text("Add a photo")
                            .textStyle(.label)
                    }
                    .foregroundStyle(Color.contentSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
                    .fieldSurface()
                }
            }
            .overlay(alignment: .bottomLeading) {
                if selectedImage != nil { removePhotoButton }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }

    private var removePhotoButton: some View {
        Button {
            selectedPhotoItem = nil
            selectedImage = nil
        } label: {
            Image(systemName: "trash")
                .font(.system(size: SymbolSize.control, weight: .medium))
                .foregroundStyle(Color.contentOnInverse)
                .frame(width: 46, height: 46)
                .background(Circle().fill(Color.destructive))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove this photo")
        .padding(Spacing.m)
    }

    private var ingredients: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Ingredients")
                .textStyle(.label)
                .foregroundStyle(Color.contentSecondary)

            ForEach($recipe.ingredients) { $ingredient in
                IngredientRowView(ingredient: $ingredient) {
                    removeIngredient(ingredient)
                }
                .fieldSurface()
            }

            Button(action: addNewIngredient) {
                Label("Add an ingredient", systemImage: "plus.circle")
            }
            .buttonStyle(.textAction)
            .padding(.top, Spacing.xs)
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
        if showRequiredNameError { return }

        recipe.ingredients = recipe.ingredients.filter { $0.name.trimmingCharacters(in: .whitespaces) != "" }

        if let jpegData = selectedImage?.jpegData(compressionQuality: 0.8) {
            recipe.imageData = jpegData
        } else {
            recipe.imageData = nil
        }

        cookbook.commit(recipe, into: modelContext)
        dismiss()
    }
}

#Preview {
    let ingredient1 = Ingredient(name: "Tomato", measurement: "2")
    let ingredient2 = Ingredient(name: "Sugar", measurement: "200g")

    NavigationStack {
        EditRecipeView(recipe: Recipe(name: "", category: .beef, thumbnailURL: "", ingredients: [ingredient1, ingredient2], calories: nil, totalCookTime: nil))
    }
    .previewStores()
}
