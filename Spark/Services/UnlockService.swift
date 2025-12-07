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

        // Already unlocked → do nothing
        if entry.unlockedAt != nil { return false }

        // Check if there are any conditions set
        let hasConditions = entry.geofence != nil ||
                            entry.weather != nil ||
                            entry.emotion != nil

        // If no conditions → unlock immediately
        if !hasConditions {
            return true
        }

        // ----------------------------------------------------------
        // Location
        // ----------------------------------------------------------
        if let gf = entry.geofence {
            guard let loc = location.currentLocation else { return false }
            if !location.isWithinGeofence(gf, from: loc) {
                return false
            }
        }

        // ----------------------------------------------------------
        // Weather
        // ----------------------------------------------------------
        if let requiredWeather = entry.weather {
            guard let currentWeather = weather.lastWeather else { return false }
            if currentWeather != requiredWeather {
                return false
            }
        }

        // ----------------------------------------------------------
        // Emotion
        // ----------------------------------------------------------
        if let requiredEmotion = entry.emotion {
            guard let current = emotion.currentEmotion else { return false }
            if current != requiredEmotion {
                return false
            }
        }

        // All required conditions match
        return true
    }
}
