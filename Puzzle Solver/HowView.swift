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
                    Text("Welcome to Puzzle Solver!\n\nThe solver screen now uses the shared cube-solving service. It always returns a clear status instead of loading forever.\n\nCurrent status:\n1. 2×2 uses a bounded IDA* path with timeout and node limits.\n2. 3×3 solving is being upgraded and is not available yet.\n3. 4×4 and 5×5 are safe reduction-method placeholders.\n\nStatuses include Solving…, Invalid cube, Solver unavailable, Could not solve quickly, and Solved.")

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
