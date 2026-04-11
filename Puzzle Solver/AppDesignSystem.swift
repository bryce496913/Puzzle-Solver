//
//  AppDesignSystem.swift
//  Puzzle Solver
//
//  Created by Codex on 11/04/2026.
//

import SwiftUI

// Centralized app design tokens for consistent styling.
enum AppTheme {
    enum Colors {
        static let background = Color.black
        static let surface = Color(red: 0.12, green: 0.04, blue: 0.2)
        static let accent = Color(red: 0.72, green: 0.29, blue: 0.95)
        static let highlight = Color(red: 0.98, green: 0.32, blue: 0.67)
        static let text = Color.white
    }

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
    }

    enum CornerRadius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
    }
}

enum AppTextStyle {
    case h1
    case h2
    case h3
    case paragraph

    var font: Font {
        switch self {
        case .h1:
            return .system(size: 16, weight: .semibold, design: .rounded)
        case .h2:
            return .system(size: 14, weight: .semibold, design: .rounded)
        case .h3:
            return .system(size: 12, weight: .medium, design: .rounded)
        case .paragraph:
            return .system(size: 10, weight: .regular, design: .rounded)
        }
    }

    var lineSpacing: CGFloat {
        switch self {
        case .h1, .h2:
            return 2
        case .h3, .paragraph:
            return 1
        }
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appTextStyle(.h2)
            .foregroundStyle(AppTheme.Colors.text)
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.small)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [AppTheme.Colors.accent, AppTheme.Colors.highlight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AppSolidButtonStyle: ButtonStyle {
    let fillColor: Color

    init(fillColor: Color = AppTheme.Colors.accent) {
        self.fillColor = fillColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appTextStyle(.h2)
            .foregroundStyle(AppTheme.Colors.text)
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.small)
            .frame(maxWidth: .infinity)
            .background(fillColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(AppTheme.Colors.text.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct AppTextStyleModifier: ViewModifier {
    let style: AppTextStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .lineSpacing(style.lineSpacing)
            .foregroundStyle(AppTheme.Colors.text)
    }
}

private struct AppSurfaceCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .stroke(AppTheme.Colors.accent.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: AppTheme.Colors.background.opacity(0.35), radius: 12, y: 6)
    }
}

extension View {
    func appTextStyle(_ style: AppTextStyle) -> some View {
        modifier(AppTextStyleModifier(style: style))
    }

    func appSurfaceCard() -> some View {
        modifier(AppSurfaceCardModifier())
    }

    // Convenience for places where applying a ButtonStyle directly isn't ergonomic.
    func appPrimaryButton() -> some View {
        self.buttonStyle(AppPrimaryButtonStyle())
    }
}
