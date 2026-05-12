//
//  MainMenuView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct MainMenuView: View {
    @AppStorage("SolverDebugLoggingEnabled") private var debugLoggingEnabled = false

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Puzzle")
                    .foregroundColor(Color(hex: 0xff99cc))
                    .font(.system(size: 60))

                Text("Solver")
                    .foregroundColor(Color(hex: 0xccffff))
                    .font(.system(size: 60))

                Spacer()

                NavigationLink(
                    destination: NewPuzzleView(),
                    label: {
                        Text("New Puzzle")
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color(hex: 0x99ccff))
                            .cornerRadius(10)
                    }
                )


                NavigationLink(
                    destination: TwistyPuzzleInputView(),
                    label: {
                        Text("Twisty Puzzles")
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color(hex: 0x99ffcc))
                            .cornerRadius(10)
                    }
                )

                NavigationLink(
                    destination: LogicPuzzleMenuView(),
                    label: {
                        Text("Logic Puzzles")
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color(hex: 0xccffff))
                            .cornerRadius(10)
                    }
                )

                NavigationLink(
                    destination: MechanicalPuzzleMenuView(),
                    label: {
                        Text("Mechanical Puzzles")
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color(hex: 0xffcc99))
                            .cornerRadius(10)
                    }
                )

                Toggle("Debug logging", isOn: $debugLoggingEnabled)
                    .foregroundColor(.white)
                    .frame(width: 200)

                NavigationLink(
                    destination: DiagnosticsView(),
                    label: {
                        Text("Diagnostics")
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color(hex: 0xffffcc))
                            .cornerRadius(10)
                    }
                )

                NavigationLink(
                    destination: HowView(),
                    label: {
                        Text("How")
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color(hex: 0xccffff))
                            .cornerRadius(10)
                    }
                )

                Button(action: {
                    // Close the app
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("Exit")
                        .foregroundColor(.black)
                        .frame(width: 200, height: 50)
                        .background(Color(hex: 0xff99cc))
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
        .navigationBarHidden(true) // Hide the navigation bar
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}


struct DiagnosticsView: View {
    private var lastStatus: SolveStatusSnapshot { SolverDiagnosticsStore.shared.lastSolveStatus }

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            List {
                Section(header: Text("Puzzle Modes")) {
                    ForEach(PuzzleModeRegistry.diagnostics) { mode in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(mode.name)
                                Text(mode.enabled ? "Enabled" : "Disabled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(mode.solverAvailable ? "Solver ready" : "No solver")
                                .font(.caption)
                                .foregroundColor(mode.solverAvailable ? .green : .red)
                        }
                    }
                }

                Section(header: Text("Example Presets")) {
                    ForEach(ExamplePuzzlePresets.all) { preset in
                        VStack(alignment: .leading) {
                            Text(preset.title)
                            Text("\(preset.category): \(preset.detail)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Last Solve")) {
                    Text("Mode: \(lastStatus.modeName)")
                    Text("Status: \(lastStatus.state.rawValue)")
                    Text("Detail: \(lastStatus.detail)")
                }

                Section(header: Text("Build")) {
                    Text("Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Debug")")
                    Text("Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Local")")
                }
            }
        }
        .navigationTitle("Diagnostics")
    }
}
