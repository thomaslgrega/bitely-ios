import SwiftUI

/// A full-bleed `surfaceInverse` panel at `promo` radius, carrying a heading, subcopy, a
/// capsule button, and an optional image bleeding off the trailing corner.
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

                VStack(alignment: .leading, spacing: Spacing.s + 2) {
                    Text(heading)
                        .textStyle(.display)
                        .foregroundStyle(Color.contentOnInverse)

                    Text(subcopy)
                        .textStyle(.meta)
                        .foregroundStyle(Color.contentOnInverse.opacity(0.7))

                    Text(actionTitle)
                        .textStyle(.label)
                        .foregroundStyle(Color.contentPrimary)
                        .padding(.horizontal, Spacing.xxl - 2)
                        .padding(.vertical, Spacing.m)
                        .background(Capsule().fill(Color.surface))
                        .padding(.top, Spacing.xs + 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.xxl - 2)
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
