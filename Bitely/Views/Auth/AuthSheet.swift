import SwiftUI

/// The share gate: signing in is the whole point of the sheet, so it closes on success.
struct AuthSheet: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                AuthFormView()
                    .padding(Spacing.xl)
            }
            .background(Color.surface)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .tint(Color.contentPrimary)
                }
            }
            .toolbarBackground(Color.surface, for: .navigationBar)
            .onChange(of: authStore.isAuthenticated) { _, signedIn in
                if signedIn { dismiss() }
            }
        }
    }
}

#Preview {
    let authStore = AuthStore()
    AuthSheet()
        .environment(authStore)
        .environment(AuthService(api: APIClient(authStore: authStore), authStore: authStore))
}
