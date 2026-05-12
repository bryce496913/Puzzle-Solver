//
//  ContentView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("HasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("PreferredAppearance") private var preferredAppearance = AppAppearanceOption.system.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSplash = true

    var body: some View {
        NavigationView {
            ZStack {
                if hasCompletedOnboarding {
                    MainMenuView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }

                if showSplash {
                    SplashView()
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.96).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(AppAppearanceOption(rawValue: preferredAppearance)?.colorScheme)
        .onAppear(perform: dismissSplash)
    }

    private func dismissSplash() {
        let delay = reduceMotion ? 0.2 : 0.9
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: reduceMotion ? 0.1 : 0.35)) {
                showSplash = false
            }
        }
    }
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 4) {
                Text("Puzzle")
                    .appTitleStyle(color: AppTheme.pink)
                Text("Solver")
                    .appTitleStyle(color: AppTheme.cyan)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Puzzle Solver")
        }
    }
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPage = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Puzzle")
                        .appTitleStyle(color: AppTheme.pink)
                    Text("Solver")
                        .appTitleStyle(color: AppTheme.cyan)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Puzzle Solver")
                .padding(.top, 24)

                TabView(selection: $selectedPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: selectedPage)

                Button(action: primaryAction) {
                    Text(selectedPage == pages.count - 1 ? "Start Solving" : "Continue")
                        .appButtonLabel()
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .accessibilityHint(selectedPage == pages.count - 1 ? "Opens the main puzzle menu." : "Shows the next onboarding page.")

                Button("Skip") {
                    completeOnboarding()
                }
                .buttonStyle(AppSecondaryButtonStyle())
                .accessibilityHint("Skips onboarding and opens the main puzzle menu.")
                .padding(.bottom, 16)
            }
            .padding()
        }
        .navigationBarHidden(true)
    }

    private func primaryAction() {
        if selectedPage < pages.count - 1 {
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9)) {
                selectedPage += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: reduceMotion ? 0.1 : 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: page.symbol)
                .font(.system(size: 52, weight: .semibold))
                .foregroundColor(page.color)
                .accessibilityHidden(true)

            Text(page.title)
                .font(.title2.weight(.bold))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)

            Text(page.message)
                .font(.body)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let message: String
    let color: Color

    static let pages = [
        OnboardingPage(symbol: "square.grid.3x3.fill", title: "Build your puzzle", message: "Enter sliding, logic, twisty, or mechanical puzzle states with guided input screens and examples.", color: AppTheme.blue),
        OnboardingPage(symbol: "bolt.horizontal.circle.fill", title: "Solve with feedback", message: "Solvers validate input, show bounded loading states, and return clear next steps when a puzzle cannot be solved.", color: AppTheme.green),
        OnboardingPage(symbol: "accessibility", title: "Made for everyday use", message: "Version 1 includes Dynamic Type, VoiceOver labels, dark-mode polish, and TestFlight-ready release metadata.", color: AppTheme.pink)
    ]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
