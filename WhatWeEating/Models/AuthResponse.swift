//
//  AuthResponse.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 1/28/26.
//

import Foundation

struct AuthResponse: Decodable {
    let accessToken: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}
