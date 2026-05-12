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
}

enum AppTheme {
    static let pink = Color(hex: 0xff99cc)
    static let cyan = Color(hex: 0xccffff)
    static let blue = Color(hex: 0x99ccff)
    static let green = Color(hex: 0x99ffcc)
    static let amber = Color(hex: 0xffcc99)
    static let lavender = Color(hex: 0xccccff)

    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let cardBackground = Color(.secondarySystemBackground).opacity(0.92)
    static let elevatedBackground = Color(.systemBackground)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.secondarySystemBackground), Color.black.opacity(0.92)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum AppAppearanceOption: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension Text {
    func appTitleStyle(color: Color) -> some View {
        self
            .foregroundColor(color)
            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
            .minimumScaleFactor(0.7)
    }

    func appButtonLabel() -> some View {
        self
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 50)
    }
}

struct AppButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.black)
            .background(color.opacity(configuration.isPressed ? 0.78 : 1))
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
