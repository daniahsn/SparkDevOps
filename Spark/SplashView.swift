//
//  SplashView.swift
//  Spark
//
//  Simple splash screen entry point
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        Group {
            if isActive {
                ContentView()
            } else {
                ZStack {
                    BrandStyle.accent
                        .ignoresSafeArea()
                    
                    Text("Spark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Show splash for 1.5 seconds then transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isActive = true
                }
            }
        }
    }
}

#Preview {
    SplashView()
}

