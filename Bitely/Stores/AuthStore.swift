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

    @ObservationIgnored private let defaults: UserDefaults

    var isAuthenticated: Bool {
        accessToken != nil
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let token = defaults.string(forKey: Self.tokenKey)
        self.accessToken = (token?.isEmpty == false) ? token : nil
    }

    func setSession(token: String, user: User) {
        accessToken = token
        self.user = user
        defaults.set(token, forKey: Self.tokenKey)
    }

    func signOut() {
        accessToken = nil
        user = nil
        defaults.removeObject(forKey: Self.tokenKey)
    }
}
