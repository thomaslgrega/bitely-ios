import SwiftUI

/// The two fields and the two actions, with no chrome of its own, so it can be the whole
/// of the share gate's sheet or a panel inside signed-out Settings.
struct AuthFormView: View {
    @Environment(AuthService.self) private var authService

    @State private var form = AuthForm()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text(form.title)
                .textStyle(.display)
                .foregroundStyle(Color.contentPrimary)

            FormField(label: "Email") {
                TextField("you@example.com", text: $form.email)
                    .textStyle(.body)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }

            FormField(label: "Password") {
                SecureField("Password", text: $form.password)
                    .textStyle(.body)
                    .textContentType(form.mode == .logIn ? .password : .newPassword)
            }

            if let errorMessage = form.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .textStyle(.meta)
                    .foregroundStyle(Color.destructive)
            }

            Button(form.title) {
                Task { await submit() }
            }
            .buttonStyle(.primary)
            .disabled(!form.canSubmit)

            Button(form.switchTitle) {
                form.switchMode()
            }
            .buttonStyle(.textAction)
        }
    }

    private func submit() async {
        form.errorMessage = nil
        form.isLoading = true
        defer { form.isLoading = false }

        do {
            switch form.mode {
            case .logIn:
                try await authService.login(email: form.email, password: form.password)
            case .createAccount:
                try await authService.register(email: form.email, password: form.password)
            }
        } catch {
            form.errorMessage = "Failed. Check your email/password and try again."
        }
    }
}

#Preview {
    let authStore = AuthStore()
    AuthFormView()
        .padding(Spacing.xl)
        .background(Color.surface)
        .environment(authStore)
        .environment(AuthService(api: APIClient(authStore: authStore), authStore: authStore))
}
