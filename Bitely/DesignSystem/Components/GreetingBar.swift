import SwiftUI

/// Avatar, greeting, and trailing controls. The avatar always opens settings, signed in or
/// out, so the way back to an account is in the same place whether or not there is one.
struct GreetingBar<Trailing: View>: View {
    let greeting: String
    /// Nil when signed out: the avatar falls back to a symbol and the second line is dropped.
    let name: String?
    var avatarTint: FoodCategory = .breakfast
    let onOpenSettings: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: Spacing.m) {
            Button(action: onOpenSettings) { avatar }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")

            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                if let name {
                    Text(name)
                }
            }
            .textStyle(.greeting)
            .foregroundStyle(Color.contentPrimary)

            Spacer()

            trailing()
        }
    }

    @ViewBuilder
    private var avatar: some View {
        Circle()
            .fill(avatarTint.tint)
            .frame(width: 46, height: 46)
            .overlay {
                if let monogram {
                    Text(monogram)
                        .textStyle(.greeting)
                        .foregroundStyle(Color.contentPrimary)
                } else {
                    Image(systemName: "person")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.contentPrimary)
                }
            }
    }

    private var monogram: String? {
        name?.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() }
    }
}

#Preview {
    VStack(spacing: Spacing.xxl) {
        GreetingBar(greeting: "Welcome,", name: "Nicky M.", onOpenSettings: {}) {
            CircleIconButton(systemImage: "magnifyingglass", accessibilityLabel: "Pantry Search") {}
        }
        GreetingBar(greeting: "Welcome", name: nil, onOpenSettings: {}) {
            CircleIconButton(systemImage: "gearshape", accessibilityLabel: "Settings") {}
        }
    }
    .padding()
    .background(Color.surface)
}
