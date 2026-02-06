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

    var body: some View {
        NavigationStack {
            Group {
                if authStore.isAuthenticated {
                    VStack(spacing: 12) {
                        Text("Account: \(authStore.user?.email ?? "N/A")")
                            .font(.title3)
                            .foregroundStyle(Color.secondaryMain)
                        Button("Sign Out") {
                            authStore.signOut()
                            dismiss()
                        }
                    }
                    .padding()
                } else {
                    AuthSheet()
                }
            }
            .navigationTitle("Settings")
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
