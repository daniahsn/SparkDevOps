//
//  WeatherService.swift
//  Spark
//
//  Created by Julius Jung on 20.11.2025.
//

import Foundation
import CoreLocation
import OpenMeteoSdk
import Combine

// MARK: - Weather Enum

enum Weather: String, Codable, Hashable {
    case clear
    case partlyCloudy
    case cloudy
    case foggy
    case drizzle
    case rain
    case freezingRain
    case snow
    case hail
    case thunderstorm
    case unknown
    
    var displayName: String {
        switch self {
        case .partlyCloudy:
            return "Partly Cloudy"
        case .freezingRain:
            return "Freezing Rain"
        default:
            return rawValue.capitalized
        }
    }
}

// MARK: - Weather Service

final class WeatherService: ObservableObject {

    @Published private(set) var lastWeather: Weather?
    @Published private(set) var lastCoordinates: CLLocationCoordinate2D?

    func getWeather(from code: Int) -> Weather {
        switch code {
        case 0: return .clear
        case 1, 2: return .partlyCloudy
        case 3: return .cloudy
        case 45, 48: return .foggy
        case 51, 53, 55: return .drizzle
        case 56, 57: return .freezingRain
        case 61, 63, 65: return .rain
        case 66, 67: return .freezingRain
        case 71, 73, 75: return .snow
        case 77: return .hail
        case 80, 81, 82: return .rain
        case 85, 86: return .snow
        case 95, 96, 99: return .thunderstorm
        default: return .unknown
        }
    }

    func fetchWeather(lat: Double, lon: Double) async throws -> Weather {
        let url = URL(string:
            "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=weathercode&format=flatbuffers"
        )!

        let responses = try await WeatherApiResponse.fetch(url: url)
        guard let response = responses.first,
              let current = response.current,
              let variable = current.variables(at: 0) else {
            throw URLError(.badServerResponse)
        }

        let weather = getWeather(from: Int(variable.value))

        await MainActor.run {
            self.lastWeather = weather
            self.lastCoordinates = .init(latitude: lat, longitude: lon)
        }

        return weather
    }
}
