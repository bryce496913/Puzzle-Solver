//
//  ContentView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct AppRootView: View {
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            NavigationStack {
                MainMenuView()
            }
            .opacity(isShowingSplash ? 0 : 1)

            if isShowingSplash {
                LaunchSplashView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: isShowingSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isShowingSplash = false
            }
        }
    }
}

struct LaunchSplashView: View {
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

struct ContentView: View {
    var body: some View {
        AppRootView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
