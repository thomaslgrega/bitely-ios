import SwiftUI

/// A named thing on a card, with a control that removes it — design-system.md, ListRowCard.
/// The rows of a Meal Plan Day and the Shopping Lists on Shop.
///
/// The trailing control is a `Button` beside the card rather than inside it: a button nested
/// in another button does not reliably take its own taps.
struct ListRowCard: View {
    let title: String
    var removeLabel: String
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.m) {
            Button(action: onTap) {
                Text(title)
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.contentPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onRemove) {
                Image(systemName: "minus.circle")
                    .font(.system(size: SymbolSize.control, weight: .medium))
                    .foregroundStyle(Color.destructive)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(removeLabel)
        }
        .cardFace()
    }
}

extension View {
    /// The raised panel a card is drawn on: rows on Plan and Shop, Matches on Pantry
    /// Search — design-system.md, ListRowCard.
    func cardFace() -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)

        return padding(Spacing.l)
            .background(shape.fill(Color.surfaceRaised))
            .overlay(shape.strokeBorder(Color.border, lineWidth: 1))
    }
}

#Preview {
    VStack(spacing: Spacing.m) {
        ListRowCard(title: "French Toast", removeLabel: "Remove French Toast", onTap: {}, onRemove: {})
        ListRowCard(title: "Costco", removeLabel: "Delete Costco", onTap: {}, onRemove: {})
    }
    .padding()
    .background(Color.surface)
}
