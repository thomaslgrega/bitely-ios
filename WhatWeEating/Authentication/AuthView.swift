//
//  AuthView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 6/5/25.
//

import SwiftUI
import GoogleSignInSwift

struct AuthView: View {
    var body: some View {
        NavigationStack {
            NavigationLink {

            } label: {
                Text("Sign in with E-mail")
            }
            .font(.title2)
            .foregroundStyle(.white)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(.green)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {

            }
        }
    }
}

#Preview {
    AuthView()
}
