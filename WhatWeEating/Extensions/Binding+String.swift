//
//  Binding.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/12/25.
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

extension Binding {
    static func optionalInt(_ source: Binding<Int?>) -> Binding<String> {
        Binding<String>(
            get: {
                source.wrappedValue.map(String.init) ?? ""
            },
            set: { newValue in
                source.wrappedValue = newValue.isEmpty ? nil : Int(newValue)
            }
        )
    }
}
