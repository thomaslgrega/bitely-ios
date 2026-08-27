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

/// Press and disabled feedback for all three styles. A `ButtonStyle` cannot read
/// `isEnabled` itself — it is resolved for the label, not for `makeBody` — so this sits in
/// a modifier, and a disabled button dims rather than swapping to a second set of colors.
private struct ButtonFeedback: ViewModifier {
    let isPressed: Bool

    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .opacity(isEnabled ? (isPressed ? 0.7 : 1) : 0.4)
            .animation(.snappy(duration: 0.15), value: isPressed)
    }
}

private extension View {
    func pressFeedback(_ isPressed: Bool) -> some View {
        modifier(ButtonFeedback(isPressed: isPressed))
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
