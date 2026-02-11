//
//  AuthStore.swift
//  Bitely
//
//  Created by Thomas Grega on 1/28/26.
//

import SwiftUI

@Observable
final class AuthStore {
    private static let tokenKey = "access_token"

    var accessToken: String? = nil
    var user: User? = nil

    var isAuthenticated: Bool {
        accessToken != nil
    }

    init() {
        let token = UserDefaults.standard.string(forKey: Self.tokenKey)
        self.accessToken = (token?.isEmpty == false) ? token : nil
    }

    func setSession(token: String, user: User) {
        accessToken = token
        self.user = user
        UserDefaults.standard.set(token, forKey: Self.tokenKey)
    }

    func signOut() {
        accessToken = nil
        user = nil
        UserDefaults.standard.removeObject(forKey: Self.tokenKey)
    }
}
