import SwiftUI

/// The one way to an account, reached from Discover's avatar — docs/design/app-flow.md,
/// Settings and auth. Signed out it is the auth form; signed in it is the account and the
/// way back out.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthStore.self) private var authStore

    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if authStore.isAuthenticated {
                        account
                    } else {
                        AuthFormView()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.xl)
            }
            .background(Color.surface)
            // No navigation title: each state draws its own `display` heading, so the
            // signed-out panel is not captioned "Settings" above its own "Log In".
            .alert("Do you want to sign out?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign out", role: .destructive) {
                    authStore.signOut()
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .tint(Color.contentPrimary)
                }
            }
            .toolbarBackground(Color.surface, for: .navigationBar)
        }
    }

    private var account: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            Text("Settings")
                .textStyle(.display)
                .foregroundStyle(Color.contentPrimary)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Account")
                    .textStyle(.label)
                    .foregroundStyle(Color.contentSecondary)

                Text(authStore.user?.email ?? "Signed in")
                    .textStyle(.body)
                    .foregroundStyle(Color.contentPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fieldSurface()
            }

            Button("Sign Out") {
                showSignOutAlert = true
            }
            .buttonStyle(.secondary)
        }
    }
}

#Preview {
    let authStore = AuthStore()
    SettingsView()
        .environment(authStore)
        .environment(AuthService(api: APIClient(authStore: authStore), authStore: authStore))
}
