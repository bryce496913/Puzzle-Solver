//
//  Color+Extensions.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

extension Color {
    init(hex: Int) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: 1
        )
    }

    // Convenience aliases to reference app palette directly from Color.
    static let appBackground = AppTheme.Colors.background
    static let appSurface = AppTheme.Colors.surface
    static let appAccent = AppTheme.Colors.accent
    static let appHighlight = AppTheme.Colors.highlight
    static let appText = AppTheme.Colors.text
}
