//
//  User.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 1/28/26.
//

import Foundation

struct User: Decodable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
    }
}
