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
    static let background = Color.black
    static let surface = Color(red: 0.12, green: 0.04, blue: 0.2)
    static let accent = Color(red: 0.72, green: 0.29, blue: 0.95)
    static let highlight = Color(red: 0.98, green: 0.32, blue: 0.67)
    static let text = Color.white

    static let pink = highlight
    static let cyan = accent
    static let blue = accent
    static let green = accent
    static let amber = highlight
    static let lavender = surface

    static let primaryText = text
    static let secondaryText = text.opacity(0.72)
    static let cardBackground = surface.opacity(0.92)
    static let elevatedBackground = surface

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [background, background],
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
            .frame(minHeight: 44)
    }
}

private enum AppButtonRole {
    case primary
    case secondary
    case danger
    case disabled
}

private extension View {
    func appButtonChrome(role: AppButtonRole, isPressed: Bool) -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundColor(appButtonForegroundColor(for: role))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(appButtonBackground(for: role, isPressed: isPressed))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(appButtonBorderColor(for: role), lineWidth: role == .secondary ? 1.5 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isPressed ? 0.88 : 1)
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }

    private func appButtonForegroundColor(for role: AppButtonRole) -> Color {
        switch role {
        case .primary, .danger, .secondary:
            return AppTheme.text
        case .disabled:
            return AppTheme.text.opacity(0.62)
        }
    }

    private func appButtonBackground(for role: AppButtonRole, isPressed: Bool) -> Color {
        let opacity = isPressed ? 0.78 : 1
        switch role {
        case .primary:
            return AppTheme.accent.opacity(opacity)
        case .secondary:
            return AppTheme.surface.opacity(isPressed ? 0.82 : 1)
        case .danger:
            return AppTheme.highlight.opacity(opacity)
        case .disabled:
            return AppTheme.surface.opacity(isPressed ? 0.44 : 0.58)
        }
    }

    private func appButtonBorderColor(for role: AppButtonRole) -> Color {
        switch role {
        case .secondary:
            return AppTheme.accent
        case .disabled:
            return AppTheme.text.opacity(0.18)
        case .primary, .danger:
            return .clear
        }
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    var isDisabledAppearance = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.appButtonChrome(
            role: isEnabled && !isDisabledAppearance ? .primary : .disabled,
            isPressed: configuration.isPressed
        )
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    var isDisabledAppearance = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.appButtonChrome(
            role: isEnabled && !isDisabledAppearance ? .secondary : .disabled,
            isPressed: configuration.isPressed
        )
    }
}

struct AppDangerButtonStyle: ButtonStyle {
    var isDisabledAppearance = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.appButtonChrome(
            role: isEnabled && !isDisabledAppearance ? .danger : .disabled,
            isPressed: configuration.isPressed
        )
    }
}

struct AppDisabledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.appButtonChrome(role: .disabled, isPressed: configuration.isPressed)
    }
}
