import SwiftUI

/// The panel that carries a screen's one headline offer — design-system.md, PromoCard.
/// The whole card is the tap target, so the capsule inside it is a label, not a button.
struct PromoCard: View {
    let heading: String
    let subcopy: String
    let actionTitle: String
    var imageName: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .offset(x: 30, y: 30)
                        .opacity(0.9)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(heading)
                        .textStyle(.display)
                        .foregroundStyle(Color.contentOnInverse)

                    Text(subcopy)
                        .textStyle(.meta)
                        .foregroundStyle(Color.contentOnInverse.opacity(0.7))

                    Text(actionTitle)
                        .textStyle(.label)
                        .foregroundStyle(Color.contentPrimary)
                        .capsuleFace(fill: Color.surface)
                        .padding(.top, Spacing.xs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.xxl)
            }
            .background(Color.surfaceInverse)
            .clipShape(RoundedRectangle(cornerRadius: Radius.promo, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PromoCard(
        heading: "Cook what\nyou have",
        subcopy: "Search your recipes and shared\nones by the foods on hand",
        actionTitle: "Start searching",
        imageName: "vegetarian"
    ) {}
    .padding()
    .background(Color.surface)
}
