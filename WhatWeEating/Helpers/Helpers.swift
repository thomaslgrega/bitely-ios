//
//  Helpers.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/1/25.
//

import SwiftUI

extension Binding where Value == String? {
    func orEmpty() -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}
