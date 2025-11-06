//
//  WeatherTrigger.swift
//  Spark
//
//  Created by Julius Jung on 03.11.2025.
//

import SwiftUI
import Combine
import OpenMeteoSdk

// MARK: - Model

struct WeatherCondition: Identifiable {
    let id = UUID()
    let name: String
    let systemImage: String
    let codes: [Int]
    var isActive: Bool
}

extension Array where Element == WeatherCondition {
    static var allConditions: [WeatherCondition] {
        [
            .init(name: "Clear", systemImage: "sun.max.fill", codes: [0], isActive: false),
            .init(name: "Partly Cloudy", systemImage: "cloud.sun.fill", codes: [1, 2], isActive: false),
            .init(name: "Cloudy", systemImage: "cloud.fill", codes: [3], isActive: false),
            .init(name: "Foggy", systemImage: "cloud.fog.fill", codes: [45, 48], isActive: false),
            .init(name: "Rainy", systemImage: "cloud.rain.fill", codes: [51, 53, 55, 56, 57, 61, 63, 65, 66, 67], isActive: false),
            .init(name: "Snowy", systemImage: "cloud.snow.fill", codes: [71, 73, 75, 77, 85, 86], isActive: false),
            .init(name: "Thunderstorm", systemImage: "cloud.bolt.rain.fill", codes: [95, 96, 99], isActive: false)
        ]
    }

    static var sunnyPreview: [WeatherCondition] {
        var list = allConditions
        if let index = list.firstIndex(where: { $0.name == "Foggy" }) {
            list[index].isActive = true
        }
        return list
    }
}

// MARK: - ViewModel

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var conditions: [WeatherCondition] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showInvalidAlert = false

    func fetchWeather(latitude: Double, longitude: Double) {
        // 🟡 Detect Preview Mode
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            print("Running in SwiftUI Preview — using mock sunny data")
            self.conditions = .sunnyPreview
            return
        }
        #endif

        Task { [weak self] in
            guard let self = self else { return }
            await self.loadWeatherData(latitude: latitude, longitude: longitude)
        }
    }

    private func loadWeatherData(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let url = URL(string:
                "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=weathercode&format=flatbuffers"
            ) else {
                throw URLError(.badURL)
            }

            let responses = try await WeatherApiResponse.fetch(url: url)
            guard let response = responses.first,
                  let current = response.current,
                  let variable = current.variables(at: 0) else {
                throw URLError(.badServerResponse)
            }

            let code = Int(variable.value)
            print("🌤️ Weather code:", code)

            var updated = Array.allConditions
            for i in 0..<updated.count {
                if updated[i].codes.contains(code) {
                    updated[i].isActive = true
                }
            }

            self.conditions = updated
        } catch {
            print("❌ Weather fetch failed:", error)
            self.errorMessage = "Error fetching weather data."
            self.conditions = .sunnyPreview
        }
    }
}

// MARK: - View

struct WeatherTrigger: View {
    @StateObject private var viewModel = WeatherViewModel()

    // Eingabefelder
    @State private var latitudeText: String = "52.52"
    @State private var longitudeText: String = "13.41"
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location (Latitude / Longitude)")
                        .font(.headline)
                        .padding(.bottom, 2)

                    HStack {
                        VStack(alignment: .leading) {
                            TextField("Latitude", text: $latitudeText)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            TextField("Longitude", text: $longitudeText)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }

                        Button {
                            refreshWeather()
                        } label: {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title2)
                        }
                        .padding(.leading, 8)
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Refresh Weather")
                    }
                }
                .padding()

                // 🔹 Hauptinhalt
                if viewModel.isLoading {
                    ProgressView("Loading weather…")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(viewModel.conditions) { condition in
                        HStack {
                            Image(systemName: condition.systemImage)
                                .foregroundColor(.gray)
                            Text(condition.name)
                            Spacer()
                            Image(systemName: condition.isActive ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(condition.isActive ? .green : .gray)
                        }
                        .padding(.vertical, 4)
                    }

                    // Hinweistext für Preview-Modus (in Englisch)
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                        Text("⚠️ Note: In Preview mode, dummy data is shown because the API call cannot be performed.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .navigationTitle("Weather Conditions")
            .onAppear {
                if !isPreviewMode {
                    refreshWeather()
                } else {
                    viewModel.fetchWeather(latitude: 52.52, longitude: 13.41)
                }
            }
            .alert("Invalid Coordinates", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter valid numeric values for latitude and longitude.")
            }
        }
    }

    // MARK: - Helpers

    private var isPreviewMode: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private func refreshWeather() {
        guard let lat = Double(latitudeText),
              let lon = Double(longitudeText),
              (-90...90).contains(lat),
              (-180...180).contains(lon)
        else {
            showAlert = true
            return
        }

        viewModel.fetchWeather(latitude: lat, longitude: lon)
    }
}

// MARK: - Preview

#Preview {
    WeatherTrigger()
}
