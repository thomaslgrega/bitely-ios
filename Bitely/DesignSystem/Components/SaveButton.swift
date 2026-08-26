import SwiftUI

/// What a `SaveButton` shows and what one tap on it means. Unsaving deletes a local Recipe
/// whose ingredients and instructions may have been edited, and a heart is a light enough
/// control that a silent second tap would be destructive, so the saved state's tap raises a
/// confirmation instead of unsaving — design-system.md, SaveButton.
struct SaveControl: Equatable {
    enum Tap: Equatable {
        case save
        case confirmUnsave
    }

    let isSaved: Bool

    var tap: Tap { isSaved ? .confirmUnsave : .save }

    var symbolName: String { isSaved ? "heart.fill" : "heart" }

    var accessibilityLabel: String { isSaved ? "Remove from cookbook" : "Save recipe" }
}

struct SaveButton: View {
    let isSaved: Bool
    let onSave: () -> Void
    let onUnsave: () -> Void

    @State private var isConfirmingUnsave = false

    private var control: SaveControl { SaveControl(isSaved: isSaved) }

    var body: some View {
        Button(action: act) {
            Image(systemName: control.symbolName)
                .font(.system(size: SymbolSize.save, weight: .semibold))
                .foregroundStyle(isSaved ? Color.accent : Color.contentPrimary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.surface))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(control.accessibilityLabel)
        .confirmationDialog(
            "Remove this recipe from your cookbook?",
            isPresented: $isConfirmingUnsave,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive, action: onUnsave)
            Button("Keep", role: .cancel) {}
        } message: {
            Text("Any changes you made to its ingredients and instructions go with it.")
        }
    }

    private func act() {
        switch control.tap {
        case .save: withAnimation(.snappy, onSave)
        case .confirmUnsave: isConfirmingUnsave = true
        }
    }
}

#Preview("Both states") {
    HStack(spacing: Spacing.l) {
        SaveButton(isSaved: false, onSave: {}, onUnsave: {})
        SaveButton(isSaved: true, onSave: {}, onUnsave: {})
    }
    .padding()
    .background(Color.contentSecondary)
}
