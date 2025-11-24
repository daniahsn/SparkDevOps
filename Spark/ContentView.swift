//
//  ContentView.swift
//  Spark
//
//  Created by Julius  Jung on 03.11.2025.
//

// A skeleton starter code for this page was AI generated

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            CreateView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Create")
                }

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
        }.tint(BrandStyle.accent)
    }
}


#Preview {
    ContentView()
}
