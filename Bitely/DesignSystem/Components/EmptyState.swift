import SwiftUI

struct EmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: SymbolSize.emptyState, weight: .light))
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
