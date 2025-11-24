//
//  SparkApp.swift
//  Spark
//
//  Created by Julius  Jung on 03.11.2025.
//

import SwiftUI

@main
struct SparkApp: App {
    
    @StateObject private var env = AppEnvironment()
    
    init() {
        UITabBar.appearance().tintColor = UIColor(BrandStyle.accent)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(env.locationService)
                .environmentObject(env.weatherService)
                .environmentObject(env.emotionService)
                .environmentObject(env.storageService)
        }
    }
}
