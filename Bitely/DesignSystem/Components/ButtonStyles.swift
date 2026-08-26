import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.label)
            .foregroundStyle(Color.contentOnInverse)
            .capsuleFace(fill: Color.surfaceInverse)
            .pressFeedback(configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.label)
            .foregroundStyle(Color.contentPrimary)
            .capsuleFace(fill: Color.surface)
            // A cream capsule on the cream page needs the stroke to have an edge at all.
            .overlay(Capsule().strokeBorder(Color.border, lineWidth: 1))
            .pressFeedback(configuration.isPressed)
    }
}

struct TextActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.label)
            .foregroundStyle(Color.accent)
            .pressFeedback(configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: Self { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: Self { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == TextActionButtonStyle {
    static var textAction: Self { TextActionButtonStyle() }
}

extension View {
    /// The pill shared by the button styles and by `PromoCard`, whose capsule sits inside
    /// the card's own tap target and so cannot be a `Button`.
    func capsuleFace(fill: Color) -> some View {
        padding(.horizontal, Spacing.xxl)
            .padding(.vertical, 14)
            .background(Capsule().fill(fill))
    }
}

private extension View {
    func pressFeedback(_ isPressed: Bool) -> some View {
        opacity(isPressed ? 0.7 : 1).animation(.snappy(duration: 0.15), value: isPressed)
    }
}

#Preview {
    VStack(spacing: Spacing.l) {
        Button("Start searching") {}.buttonStyle(.primary)
        Button("Add to shopping list") {}.buttonStyle(.secondary)
        Button("View all") {}.buttonStyle(.textAction)
    }
    .padding()
    .background(Color.surface)
}
