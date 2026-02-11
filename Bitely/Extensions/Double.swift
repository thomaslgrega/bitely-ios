//
//  Double.swift
//  Bitely
//
//  Created by Thomas Grega on 12/12/25.
//

import Foundation

extension Double {
    func trimTrailingZeros() -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
