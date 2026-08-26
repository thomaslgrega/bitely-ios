import SwiftUI

/// A centred symbol, a `sectionTitle` line, a `body` line, and an optional action. Used by
/// an empty Cookbook and by signed-out states.
struct EmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Color.contentSecondary)
                .accessibilityHidden(true)

            Text(title)
                .textStyle(.sectionTitle)
                .foregroundStyle(Color.contentPrimary)

            Text(message)
                .textStyle(.body)
                .foregroundStyle(Color.contentSecondary)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
                    .fixedSize()
                    .padding(.top, Spacing.xs)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxl)
    }
}

#Preview {
    EmptyState(
        systemImage: "book.closed",
        title: "Your cookbook is empty",
        message: "Recipes you write or save from other people land here.",
        actionTitle: "Browse Today's Picks"
    ) {}
    .background(Color.surface)
}
