//
//  ContentView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isActive: Bool = false
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Puzzle")
                    .foregroundColor(Color(hex: 0xff99cc))
                    .font(.system(size: 60))
                
                Text("Solver")
                    .foregroundColor(Color(hex: 0xccffff))
                    .font(.system(size: 60))
            }
            .opacity(isActive ? 1 : 0)
            .animation(.easeInOut(duration: 1))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.isActive = true
                }
                
                // Navigate to MainMenuView after the splash screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.navigateToMainMenu()
                }
            }
        }
    }
    
    private func navigateToMainMenu() {
        // Use NavigationLink to navigate to MainMenuView
        let mainMenuView = MainMenuView()
        let contentView = NavigationView { // Assuming you want to embed in a NavigationView
            NavigationLink(destination: mainMenuView, isActive: $isActive) {
                EmptyView()
            }
        }
        UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: contentView)
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
