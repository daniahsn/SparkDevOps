//
//  LocationTrigger.swift
//  Spark
//
//  Created by Julius  Jung on 03.11.2025.
// Dania edit!

import SwiftUI
import CoreLocation
import Combine

// MARK: - Models

struct SparkEntry: Identifiable, Codable {
    let id: UUID
    var title: String
    var isLocked: Bool
    var unlockType: UnlockType?
    var unlockedAt: Date?
    var geofence: Geofence
    
    init(id: UUID = UUID(), title: String, geofence: Geofence) {
        self.id = id
        self.title = title
        self.isLocked = true
        self.unlockType = nil
        self.unlockedAt = nil
        self.geofence = geofence
    }
}

struct Geofence: Codable {
    let latitude: Double
    let longitude: Double
    let radius: Double // in meters
}

enum UnlockType: String, Codable {
    case location = "Location"
}

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let entryId: UUID
    let timestamp: Date
    let unlockType: UnlockType
    
    init(id: UUID = UUID(), entryId: UUID, timestamp: Date, unlockType: UnlockType) {
        self.id = id
        self.entryId = entryId
        self.timestamp = timestamp
        self.unlockType = unlockType
    }
}

// MARK: - Location Manager

class LocationMonitor: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startMonitoring() {
        locationManager.startUpdatingLocation()
    }
    
    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startMonitoring()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startMonitoring()
        }
    }
    
    func isWithinGeofence(_ geofence: Geofence, from location: CLLocation) -> Bool {
        let geofenceLocation = CLLocation(latitude: geofence.latitude, longitude: geofence.longitude)
        let distance = location.distance(from: geofenceLocation)
        return distance <= geofence.radius
    }
}

// MARK: - View Model

class SparkViewModel: ObservableObject {
    @Published var entries: [SparkEntry] = []
    @Published var history: [HistoryItem] = []
    
    private let entriesKey = "spark_entries"
    private let historyKey = "spark_history"
    
    init() {
        loadData()
        
        // If no entries exist, create a demo entry (San Francisco coordinates)
        if entries.isEmpty {
            let demoGeofence = Geofence(latitude: 37.7749, longitude: -122.4194, radius: 150)
            let demoEntry = SparkEntry(title: "Demo Entry", geofence: demoGeofence)
            entries.append(demoEntry)
            saveData()
        }
    }
    
    func checkAndUnlockEntries(at location: CLLocation, monitor: LocationMonitor) {
        var needsSave = false
        
        for index in entries.indices {
            // Only check locked entries
            if entries[index].isLocked {
                if monitor.isWithinGeofence(entries[index].geofence, from: location) {
                    // Unlock the entry
                    entries[index].isLocked = false
                    entries[index].unlockType = .location
                    entries[index].unlockedAt = Date() // Store in UTC
                    
                    // Add history item
                    let historyItem = HistoryItem(
                        entryId: entries[index].id,
                        timestamp: Date(),
                        unlockType: .location
                    )
                    history.insert(historyItem, at: 0) // Most recent first
                    
                    needsSave = true
                }
            }
        }
        
        if needsSave {
            saveData()
        }
    }
    
    func resetDemo() {
        entries.removeAll()
        history.removeAll()
        
        // Create fresh demo entry
        let demoGeofence = Geofence(latitude: 37.7749, longitude: -122.4194, radius: 150)
        let demoEntry = SparkEntry(title: "Demo Entry", geofence: demoGeofence)
        entries.append(demoEntry)
        
        saveData()
    }
    
    private func saveData() {
        if let entriesData = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(entriesData, forKey: entriesKey)
        }
        if let historyData = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(historyData, forKey: historyKey)
        }
    }
    
    private func loadData() {
        if let entriesData = UserDefaults.standard.data(forKey: entriesKey),
           let decodedEntries = try? JSONDecoder().decode([SparkEntry].self, from: entriesData) {
            entries = decodedEntries
        }
        
        if let historyData = UserDefaults.standard.data(forKey: historyKey),
           let decodedHistory = try? JSONDecoder().decode([HistoryItem].self, from: historyData) {
            history = decodedHistory
        }
    }
}

// MARK: - Main View

struct LocationTrigger: View {
    @StateObject private var viewModel = SparkViewModel()
    @StateObject private var locationMonitor = LocationMonitor()
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Location Status
                locationStatusView
                
                Divider()
                
                // Entries List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.entries) { entry in
                            EntryCard(entry: entry)
                        }
                        
                        // History Section
                        if !viewModel.history.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("History")
                                    .font(SparkFont.ui(20, weight: .semibold))
                                    .foregroundColor(.brandAccent)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.history) { item in
                                    HistoryCard(item: item)
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Spark")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        viewModel.resetDemo()
                    }
                    .font(SparkFont.ui(16))
                    .foregroundColor(.brandAccent)
                }
            }
        }
        .onAppear {
            locationMonitor.requestPermission()
            startLocationChecking()
        }
        .onDisappear {
            stopLocationChecking()
        }
    }
    
    private var locationStatusView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.brandAccent)
                    .font(.system(size: 16))
                
                if let location = locationMonitor.currentLocation {
                    Text("Lat: \(location.coordinate.latitude, specifier: "%.4f"), Lon: \(location.coordinate.longitude, specifier: "%.4f")")
                        .font(SparkFont.ui(13))
                        .foregroundColor(.primary)
                } else {
                    Text("Waiting for location...")
                        .font(SparkFont.ui(13))
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color.brandDominant)
    }
    
    private func startLocationChecking() {
        // Check every 2 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if let location = locationMonitor.currentLocation {
                viewModel.checkAndUnlockEntries(at: location, monitor: locationMonitor)
            }
        }
    }
    
    private func stopLocationChecking() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Entry Card View

struct EntryCard: View {
    let entry: SparkEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.title)
                    .font(SparkFont.ui(22, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: entry.isLocked ? "lock.fill" : "lock.open.fill")
                    .foregroundColor(entry.isLocked ? .brandAccent : .brandSecondary)
                    .font(.system(size: 24))
            }
            
            // Status
            HStack {
                if entry.isLocked {
                    Label("Locked", systemImage: "lock.fill")
                        .foregroundColor(.brandAccent)
                        .font(SparkFont.ui(15))
                } else {
                    Label("Unlocked (\(entry.unlockType?.rawValue ?? "Unknown"))", systemImage: "lock.open.fill")
                        .foregroundColor(.brandSecondary)
                        .font(SparkFont.ui(15))
                }
                
                Spacer()
            }
            
            // Geofence Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Geofence:")
                    .font(SparkFont.ui(12))
                    .foregroundColor(.secondary)
                Text("Lat: \(entry.geofence.latitude, specifier: "%.4f"), Lon: \(entry.geofence.longitude, specifier: "%.4f")")
                    .font(SparkFont.ui(11))
                    .foregroundColor(.secondary)
                Text("Radius: \(Int(entry.geofence.radius))m")
                    .font(SparkFont.ui(11))
                    .foregroundColor(.secondary)
            }
            
            // Unlock timestamp (if unlocked)
            if let unlockedAt = entry.unlockedAt {
                Text("Unlocked: \(formatDate(unlockedAt))")
                    .font(SparkFont.ui(12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.brandDominant)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(entry.isLocked ? Color.brandAccent.opacity(0.5) : Color.brandSecondary.opacity(0.5), lineWidth: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.timeZone = .current // Display in local time
        return formatter.string(from: date)
    }
}

// MARK: - History Card View

struct HistoryCard: View {
    let item: HistoryItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundColor(.brandAccent)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Unlocked via \(item.unlockType.rawValue)")
                    .font(SparkFont.ui(15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(formatDate(item.timestamp))
                    .font(SparkFont.ui(12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.brandDominant.opacity(0.8))
        )
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.timeZone = .current // Display in local time
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    LocationTrigger()
}
