//
//  LocationService.swift
//  Spark
//
//  Created by Julius  Jung on 20.11.2025.
//

import Foundation
import CoreLocation
import Combine


struct Geofence: Codable, Hashable {
    var id: UUID
    let latitude: Double
    let longitude: Double
    let radius: Double
    
    init(id: UUID = UUID(), latitude: Double, longitude: Double, radius: Double) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
    
    // Custom decoder to handle missing id field from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // id is optional in JSON, use default if missing
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        radius = try container.decode(Double.self, forKey: .radius)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, radius
    }
}

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startMonitoring() {
        manager.startUpdatingLocation()
    }

    func stopMonitoring() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startMonitoring()
        default:
            stopMonitoring()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func isWithinGeofence(_ geofence: Geofence, from location: CLLocation) -> Bool {
        let target = CLLocation(latitude: geofence.latitude, longitude: geofence.longitude)
        return location.distance(from: target) <= geofence.radius
    }
}
