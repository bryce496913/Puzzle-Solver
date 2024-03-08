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
                    Text("Welcome to Puzzle Solver!\n\nTo use the app:\n1. Open the app and go to the 'New Puzzle' section.\n2. Assign numbers to 8 out of the 9 tiles.\n3. Ask the app to solve the puzzle.\n4. Watch the app use the A* algorithm to find the solution.\n5. Enjoy the magic of puzzle-solving!\n\nFeel free to explore other features in the main menu.")

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
