import SwiftUI

/// What a selection indicator draws and how the row carrying it reads. The indicator is
/// decorative — the row's own text is its label — so the picked state is announced by the
/// trait rather than by a second string VoiceOver would read after the name.
struct SelectionState: Equatable {
    let isSelected: Bool

    var symbolName: String { isSelected ? "checkmark.circle.fill" : "circle" }

    var tint: ColorToken { isSelected ? .accent : .contentSecondary }

    var traits: AccessibilityTraits { isSelected ? [.isButton, .isSelected] : .isButton }
}

/// The circle that fills when a row or a tile is picked — design-system.md,
/// SelectionIndicator. Sized like the save heart, since both sit over a thumbnail.
struct SelectionIndicator: View {
    let isSelected: Bool

    private var state: SelectionState { SelectionState(isSelected: isSelected) }

    var body: some View {
        Image(systemName: state.symbolName)
            .font(.system(size: SymbolSize.save, weight: .semibold))
            .foregroundStyle(Color(state.tint))
            .accessibilityHidden(true)
    }
}

extension SelectionIndicator {
    /// Over a thumbnail the symbol needs a ground of its own: an unfilled circle on a photo
    /// is invisible at this weight.
    var onThumbnail: some View {
        frame(width: 34, height: 34).background(Circle().fill(Color.surface))
    }
}

#Preview {
    HStack(spacing: Spacing.l) {
        SelectionIndicator(isSelected: true)
        SelectionIndicator(isSelected: false)
        SelectionIndicator(isSelected: true).onThumbnail
    }
    .padding()
    .background(Color.surface)
}
