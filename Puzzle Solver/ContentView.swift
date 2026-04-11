//
//  ContentView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct ContentView: View {
    @State private var launchPhase: LaunchPhase = .splash

    var body: some View {
        NavigationStack {
            MainMenuView()
        }
        .overlay {
            if launchPhase == .splash {
                LaunchSplashView()
                    .transition(.opacity)
            }
        }
        .task {
            guard launchPhase == .splash else { return }

            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                launchPhase = .menu
            }
        }
    }
}

private enum LaunchPhase {
    case splash
    case menu
}

private struct LaunchSplashView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            Text("Puzzle Solver")
                .appTextStyle(.h1)
                .foregroundStyle(AppTheme.Colors.highlight)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
