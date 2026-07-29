//
//  Puzzle_SolverApp.swift
//  Puzzle Solver
//
//  Created by Aditi Abrol on 30/1/24.
//

import SwiftUI

@main
struct Puzzle_SolverApp: App {
    @StateObject private var launchState = LaunchStateController()

    var body: some Scene {
        WindowGroup {
            AppRootView(launchState: launchState)
        }
    }
}
