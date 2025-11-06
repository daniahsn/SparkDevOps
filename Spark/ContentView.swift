//
//  ContentView.swift
//  Spark
//
//  Created by Julius  Jung on 03.11.2025.
//

import SwiftUI

struct ContentView: View {
    // Test comment to check Git
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Hello World", destination: HelloWorld())
                NavigationLink("Styles", destination: StyleDemo())
                NavigationLink("Local storage", destination: LocalStorage())
                NavigationLink("Location Trigger", destination: LocationTrigger())
                NavigationLink("Weather Trigger", destination: WeatherTrigger())
                NavigationLink("Emotion Trigger", destination: EmotionTrigger())
                NavigationLink("Lock and Unlock Tracking", destination: LockAndUnlockTracking())
            }
            .navigationTitle("Menu")
        }
    }
}

#Preview {
    ContentView()
}
