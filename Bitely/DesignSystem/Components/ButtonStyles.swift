import SwiftUI

/// `contentOnInverse` on a `surfaceInverse` capsule.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.label)
            .foregroundStyle(Color.contentOnInverse)
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.m + 2)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(Color.surfaceInverse))
            .pressFeedback(configuration.isPressed)
    }
}

/// `contentPrimary` on a `cream` capsule, for the choice that sits beside a primary one.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.label)
            .foregroundStyle(Color.contentPrimary)
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.m + 2)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(Color.surface))
            .overlay(Capsule().strokeBorder(Color.border, lineWidth: 1))
            .pressFeedback(configuration.isPressed)
    }
}

/// A bare `label` in `accent`: section actions, links, anything that must not read as a
/// control with weight of its own.
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
