//
//  SettingsView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 2/5/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthStore.self) private var authStore

    @State private var showSignoutAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if authStore.isAuthenticated {
                    VStack(spacing: 12) {
                        Text("Account: \(authStore.user?.email ?? "N/A")")
                            .font(.title3)
                            .foregroundStyle(Color.secondaryMain)
                        Button("Sign Out") {
                            showSignoutAlert = true
                        }
                    }
                    .padding()
                } else {
                    AuthSheet()
                }
            }
            .navigationTitle("Settings")
            .alert("Do you want to signout?", isPresented: $showSignoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign out", role: .destructive) {
                    authStore.signOut()
                    dismiss()
                }
            }
            .toolbar {
                if authStore.isAuthenticated {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
