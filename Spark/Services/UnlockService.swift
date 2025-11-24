//
//  UnlockService.swift
//  Spark
//
//  Created by Julius  Jung on 20.11.2025.
//

import Foundation
import CoreLocation

final class UnlockService {

    let location: LocationService
    let weather: WeatherService
    let emotion: EmotionService

    init(location: LocationService,
         weather: WeatherService,
         emotion: EmotionService) {
        self.location = location
        self.weather = weather
        self.emotion = emotion
    }

    func shouldUnlock(_ entry: SparkEntry) -> Bool {

        if entry.unlockedAt != nil { return false }

        guard Date() >= entry.earliestUnlock else {
            return false
        }

        // geofence
        if let gf = entry.geofence {
            guard let loc = location.currentLocation else { return false }
            if !location.isWithinGeofence(gf, from: loc) { return false }
        }

        // weather
        if let required = entry.weather {
            guard let current = weather.lastWeather else { return false }
            if current != required { return false }
        }

        // emotion
        if let requiredEmotion = entry.emotion {
            guard let current = emotion.currentEmotion else { return false }
            if current != requiredEmotion { return false }
        }

        return true
    }
}

