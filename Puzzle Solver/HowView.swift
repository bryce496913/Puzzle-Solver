//
//  HowView.swift
//  Puzzle Solver
//
//  Created by Bryceon 30/1/24.
//

import SwiftUI

struct HowView: View {
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack {
                Text("How")
                    .foregroundColor(Color(hex: 0xff99cc))
                    .font(.system(size: 60))
                    .padding(.top, 50)

                ScrollView {
                    Text("Welcome to Puzzle Solver!\n\nThe solver screen now uses shared bounded solving infrastructure. Every active solver returns a clear state instead of loading forever.\n\nCurrent status:\n1. 2×2, 3×3, Pyraminx, and Skewb use bounded solvers with timeout and node limits.\n2. 4×4, 5×5, Megaminx, and Square-1 are safe placeholders that return unavailable instead of running indefinitely.\n3. Sliding, Sudoku, Rush Hour, Maze, and Chess solvers share solved/invalid/failed/timed-out status reporting.\n\nStatuses include Solving…, Solved, Invalid, Failed, Timed out, and Solver unavailable.")

                        .foregroundColor(.white)
                        .padding()
                        .multilineTextAlignment(.center)
                        .font(.system(size: 20))
                }

                Spacer()

                NavigationLink(
                    destination: MainMenuView(),
                    label: {
                        Text("Back")
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color(hex: 0xff99cc))
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                    }
                )
            }
            .padding()
        }
        .navigationBarHidden(true) // Hide the navigation bar
    }
}

struct HowView_Previews: PreviewProvider {
    static var previews: some View {
        HowView()
    }
}
