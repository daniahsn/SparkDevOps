//
//  SparkApp.swift
//  Spark
//
//  Created by Julius  Jung on 03.11.2025.
//

import SwiftUI
import UIKit

@main
struct SparkApp: App {
    
    @StateObject private var env = AppEnvironment()
    
    init() {
        // Tab bar colors
        UITabBar.appearance().tintColor = UIColor(BrandStyle.accent)
        UITabBar.appearance().unselectedItemTintColor = UIColor(BrandStyle.textSecondary)
        
        // Navigation bar colors
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(BrandStyle.background)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(BrandStyle.accent),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(BrandStyle.accent),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(BrandStyle.accent)
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(env.locationService)
                .environmentObject(env.weatherService)
                .environmentObject(env.emotionService)
                .environmentObject(env.storageService)
        }
    }
}
