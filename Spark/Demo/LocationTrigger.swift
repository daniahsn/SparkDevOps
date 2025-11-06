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
    var content: String // The actual journal entry content
    var isLocked: Bool
    var unlockType: UnlockType?
    var unlockedAt: Date?
    var geofence: Geofence
    
    init(id: UUID = UUID(), title: String, content: String, geofence: Geofence) {
        self.id = id
        self.title = title
        self.content = content
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
        
        // If no entries exist, create demo entries
        if entries.isEmpty {
            // Demo Entry 1: Downtown SF
            let demoGeofence1 = Geofence(latitude: 37.7749, longitude: -122.4194, radius: 150)
            let demoContent1 = """
            A Perfect Afternoon in the City
            
            I walked through the bustling streets of downtown San Francisco, where the energy of the city wrapped around me like a warm blanket. The Golden Gate Bridge peeked through the fog in the distance, and I stopped by my favorite coffee shop on Market Street.
            
            The barista remembered my order—a honey lavender latte—and we chatted about the upcoming street festival. These small moments of connection remind me why I love this city so much.
            
            Grateful for today:
            - The unexpected sunshine breaking through the clouds
            - Running into an old friend at the bookstore
            - The street musician playing the most beautiful jazz
            - Taking time to notice the small details
            
            This memory belongs to this special place, waiting to be unlocked when I return.
            """
            let demoEntry1 = SparkEntry(title: "Coffee on Market Street", content: demoContent1, geofence: demoGeofence1)
            entries.append(demoEntry1)
            
            // Demo Entry 2: Current Location - This should unlock when you're here!
            let demoGeofence2 = Geofence(latitude: 37.7858, longitude: -122.4064, radius: 100)
            let demoContent2 = """
            Discovering This Moment
            
            This is the spot where something special happened. Maybe it's where you had an amazing conversation, discovered a hidden gem, or simply took a moment to breathe and appreciate the present.
            
            The beauty of Spark is that memories are tied to places. You've just unlocked this one by being here.
            
            Reflections on this place:
            - Every location holds a story waiting to be told
            - Being present in the moment is a gift
            - Your journey matters, and so does where it takes you
            - Small moments create lasting memories
            
            What will you remember about this place? Write it down, save it, and let this location forever hold this piece of your story.
            
            Welcome to Spark.
            """
            let demoEntry2 = SparkEntry(title: "A Moment Here", content: demoContent2, geofence: demoGeofence2)
            entries.append(demoEntry2)
            
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
        
        // Create fresh demo entries
        // Demo Entry 1: Downtown SF
        let demoGeofence1 = Geofence(latitude: 37.7749, longitude: -122.4194, radius: 150)
        let demoContent1 = """
        A Perfect Afternoon in the City
        
        I walked through the bustling streets of downtown San Francisco, where the energy of the city wrapped around me like a warm blanket. The Golden Gate Bridge peeked through the fog in the distance, and I stopped by my favorite coffee shop on Market Street.
        
        The barista remembered my order—a honey lavender latte—and we chatted about the upcoming street festival. These small moments of connection remind me why I love this city so much.
        
        Grateful for today:
        - The unexpected sunshine breaking through the clouds
        - Running into an old friend at the bookstore
        - The street musician playing the most beautiful jazz
        - Taking time to notice the small details
        
        This memory belongs to this special place, waiting to be unlocked when I return.
        """
        let demoEntry1 = SparkEntry(title: "Coffee on Market Street", content: demoContent1, geofence: demoGeofence1)
        entries.append(demoEntry1)
        
        // Demo Entry 2: Current Location - This should unlock when you're here!
        let demoGeofence2 = Geofence(latitude: 37.7858, longitude: -122.4064, radius: 100)
        let demoContent2 = """
        Discovering This Moment
        
        This is the spot where something special happened. Maybe it's where you had an amazing conversation, discovered a hidden gem, or simply took a moment to breathe and appreciate the present.
        
        The beauty of Spark is that memories are tied to places. You've just unlocked this one by being here.
        
        Reflections on this place:
        - Every location holds a story waiting to be told
        - Being present in the moment is a gift
        - Your journey matters, and so does where it takes you
        - Small moments create lasting memories
        
        What will you remember about this place? Write it down, save it, and let this location forever hold this piece of your story.
        
        Welcome to Spark.
        """
        let demoEntry2 = SparkEntry(title: "A Moment Here", content: demoContent2, geofence: demoGeofence2)
        entries.append(demoEntry2)
        
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
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.brandDominant, Color.brandSecondary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Location Status
                    locationStatusView
                    
                    // Entries List
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(viewModel.entries) { entry in
                                if entry.isLocked {
                                    EntryCard(entry: entry, locationMonitor: locationMonitor)
                                } else {
                                    NavigationLink(destination: EntryDetailView(entry: entry)) {
                                        EntryCard(entry: entry, locationMonitor: locationMonitor)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // History Section
                            if !viewModel.history.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(SparkFont.ui(20, weight: .semibold))
                                            .foregroundColor(.brandAccent)
                                        Text("History")
                                            .font(SparkFont.ui(24, weight: .bold))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    ForEach(viewModel.history) { item in
                                        HistoryCard(item: item)
                                    }
                                }
                                .padding(.top, 24)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Spark")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.resetDemo()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Reset")
                        }
                        .font(SparkFont.ui(16, weight: .semibold))
                        .foregroundColor(.brandAccent)
                    }
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
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.brandAccent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "location.fill")
                        .foregroundColor(.brandAccent)
                        .font(SparkFont.ui(18, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Current Location")
                            .font(SparkFont.ui(12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .kerning(0.5)
                        
                        // Permission status indicator
                        Circle()
                            .fill(locationMonitor.authorizationStatus == .authorizedWhenInUse || locationMonitor.authorizationStatus == .authorizedAlways ? Color.brandSecondary : Color.brandAccent)
                            .frame(width: 8, height: 8)
                    }
                    
                    if let location = locationMonitor.currentLocation {
                        Text("\(location.coordinate.latitude, specifier: "%.4f"), \(location.coordinate.longitude, specifier: "%.4f")")
                            .font(SparkFont.ui(15, weight: .medium))
                            .foregroundColor(.primary)
                    } else {
                        let statusText = locationMonitor.authorizationStatus == .denied ? "Permission Denied" : 
                                       locationMonitor.authorizationStatus == .notDetermined ? "Tap to Allow Location" :
                                       "Waiting for location..."
                        Text(statusText)
                            .font(SparkFont.ui(15, weight: .medium))
                            .foregroundColor(locationMonitor.authorizationStatus == .denied ? .brandAccent : .secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color.brandDominant
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
            )
        }
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

// MARK: - Entry Detail View

struct EntryDetailView: View {
    let entry: SparkEntry
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with unlock success
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.brandSecondary.opacity(0.3), Color.brandSecondary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "lock.open.fill")
                            .font(SparkFont.ui(44, weight: .bold))
                            .foregroundColor(.brandSecondary)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Memory Unlocked")
                            .font(SparkFont.ui(32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Discovered at this location")
                            .font(SparkFont.ui(16, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    Text(entry.title)
                        .font(SparkFont.ui(28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Divider()
                    
                    Text(entry.content)
                        .font(SparkFont.ui(17, weight: .regular))
                        .foregroundColor(.primary)
                        .lineSpacing(8)
                    
                    Divider()
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "map.circle.fill")
                                .foregroundColor(.brandAccent)
                            Text("Location:")
                                .font(SparkFont.ui(14, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("\(entry.geofence.latitude, specifier: "%.4f"), \(entry.geofence.longitude, specifier: "%.4f")")
                                .font(SparkFont.ui(14, weight: .regular))
                                .foregroundColor(.primary)
                        }
                        
                        if let unlockedAt = entry.unlockedAt {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.brandAccent)
                                Text("Unlocked:")
                                    .font(SparkFont.ui(14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(formatDate(unlockedAt))
                                    .font(SparkFont.ui(14, weight: .regular))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.brandSecondary.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.brandDominant, Color.brandSecondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}

// MARK: - Entry Card View

struct EntryCard: View {
    let entry: SparkEntry
    @ObservedObject var locationMonitor: LocationMonitor
    
    private var distanceToGeofence: Double? {
        guard let currentLocation = locationMonitor.currentLocation else { return nil }
        let geofenceLocation = CLLocation(latitude: entry.geofence.latitude, longitude: entry.geofence.longitude)
        return currentLocation.distance(from: geofenceLocation)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with title and lock icon
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(SparkFont.ui(26, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Status badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(entry.isLocked ? Color.brandAccent : Color.brandSecondary)
                            .frame(width: 8, height: 8)
                        
                        if entry.isLocked {
                            Text("LOCKED")
                                .font(SparkFont.ui(13, weight: .bold))
                                .foregroundColor(.brandAccent)
                        } else {
                            Text("UNLOCKED")
                                .font(SparkFont.ui(13, weight: .bold))
                                .foregroundColor(.brandSecondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(entry.isLocked ? Color.brandAccent.opacity(0.1) : Color.brandSecondary.opacity(0.15))
                    )
                }
                
                Spacer()
                
                // Lock icon with animated background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: entry.isLocked ? 
                                    [Color.brandAccent.opacity(0.2), Color.brandAccent.opacity(0.1)] :
                                    [Color.brandSecondary.opacity(0.3), Color.brandSecondary.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: entry.isLocked ? "lock.fill" : "lock.open.fill")
                        .font(SparkFont.ui(28, weight: .semibold))
                        .foregroundColor(entry.isLocked ? .brandAccent : .brandSecondary)
                }
            }
            .padding(20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Geofence Info Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "map.circle.fill")
                        .font(SparkFont.ui(16, weight: .semibold))
                        .foregroundColor(.brandAccent)
                    Text("Geofence Location")
                        .font(SparkFont.ui(14, weight: .semibold))
                        .foregroundColor(.primary)
                        .textCase(.uppercase)
                        .kerning(0.3)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Coordinates:")
                            .font(SparkFont.ui(13, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(entry.geofence.latitude, specifier: "%.4f"), \(entry.geofence.longitude, specifier: "%.4f")")
                            .font(SparkFont.ui(13, weight: .regular))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Radius:")
                            .font(SparkFont.ui(13, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(Int(entry.geofence.radius)) meters")
                            .font(SparkFont.ui(13, weight: .regular))
                            .foregroundColor(.primary)
                    }
                    
                    // Debug: Distance from current location
                    if let distance = distanceToGeofence {
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle")
                                .font(SparkFont.ui(12, weight: .medium))
                                .foregroundColor(distance <= entry.geofence.radius ? .brandSecondary : .brandAccent)
                            Text("Distance:")
                                .font(SparkFont.ui(13, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("\(Int(distance))m away")
                                .font(SparkFont.ui(13, weight: .bold))
                                .foregroundColor(distance <= entry.geofence.radius ? .brandSecondary : .brandAccent)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.leading, 24)
            }
            .padding(20)
            .padding(.top, 4)
            
            // Unlock timestamp (if unlocked)
            if let unlockedAt = entry.unlockedAt {
                Divider()
                    .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(SparkFont.ui(16, weight: .semibold))
                        .foregroundColor(.brandSecondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlocked via \(entry.unlockType?.rawValue ?? "Unknown")")
                            .font(SparkFont.ui(14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(formatDate(unlockedAt))
                            .font(SparkFont.ui(12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(SparkFont.ui(14, weight: .semibold))
                            .foregroundColor(.brandSecondary)
                        Text("Tap to view")
                            .font(SparkFont.ui(10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(Color.brandSecondary.opacity(0.08))
            }
        }
        .background(Color.brandDominant)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    entry.isLocked ? 
                        Color.brandAccent.opacity(0.3) : 
                        Color.brandSecondary.opacity(0.4),
                    lineWidth: 2
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current // Display in local time
        return formatter.string(from: date)
    }
}

// MARK: - History Card View

struct HistoryCard: View {
    let item: HistoryItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandSecondary.opacity(0.2), Color.brandSecondary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(SparkFont.ui(20, weight: .semibold))
                    .foregroundColor(.brandSecondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Unlocked via \(item.unlockType.rawValue)")
                    .font(SparkFont.ui(16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(SparkFont.ui(11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(formatDate(item.timestamp))
                        .font(SparkFont.ui(13, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(SparkFont.ui(14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(16)
        .background(Color.brandDominant)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brandSecondary.opacity(0.2), lineWidth: 1.5)
        )
        .padding(.horizontal, 20)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current // Display in local time
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    LocationTrigger()
}
