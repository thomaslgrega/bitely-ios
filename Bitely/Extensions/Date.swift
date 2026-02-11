//
//  Date.swift
//  Bitely
//
//  Created by Thomas Grega on 12/17/25.
//

import Foundation

extension Date {
    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
