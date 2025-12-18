//
//  Color.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/17/25.
//

import Foundation
import SwiftUI

extension Color {
    // Primary - Coral Orange
    static let primaryMain = Color(hex: "#FF6B35")
    static let primary50 = Color(hex: "#FFF4F0")
    static let primary100 = Color(hex: "#FFE5DC")
    static let primary200 = Color(hex: "#FFCAB8")

    // Secondary - Slate Blue
    static let secondaryMain = Color(hex: "#475569")
    static let secondary50 = Color(hex: "#F8FAFC")
    static let secondary100 = Color(hex: "#F1F5F9")
    static let secondary200 = Color(hex: "#E2E8F0")
    static let secondary400 = Color(hex: "#94A3B8")
    static let secondary700 = Color(hex: "#334155")

    // Accent - Teal
    static let accentMain = Color(hex: "#14B8A6")
    static let accent50 = Color(hex: "#F0FDFA")
    static let accent100 = Color(hex: "#CCFBF1")

    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.index(hex.startIndex, offsetBy: 1)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
