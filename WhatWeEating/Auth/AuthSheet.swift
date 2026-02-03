//
//  AuthSheet.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 1/28/26.
//

import SwiftUI

struct AuthSheet: View {
    @Environment(AuthService.self) private var authService
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss

    @State private var isRegister = false
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button(isRegister ? "Create Account" : "Log In") {
                        Task {
                            await submit()
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    Button(isRegister ? "Already have an account? Log In" : "New here? Create Account") {
                        isRegister.toggle()
                        errorMessage = nil
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(isRegister ? "Create Account" : "Log In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onChange(of: authStore.isAuthenticated) { _, loggedIn in
                if loggedIn {
                    dismiss()
                }
            }
        }
    }

    private func submit() async {
        errorMessage = nil
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            if isRegister {
                try await authService.register(email: email, password: password)
            } else {
                try await authService.login(email:email, password: password)
            }
        } catch {
            errorMessage = "Failed. Check your email/password and try again."
        }
    }
}

#Preview {
    AuthSheet()
}
