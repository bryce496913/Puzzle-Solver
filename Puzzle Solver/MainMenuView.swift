//
//  MainMenuView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct MainMenuView: View {
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
