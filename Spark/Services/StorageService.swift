//
//  StorageService.swift
//  Spark
//
//  Created by Julius  Jung on 20.11.2025.
//
import SwiftUI
import CoreLocation
import Combine
import Foundation

struct SparkEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var creationDate: Date

    // unlock triggers
    var geofence: Geofence?
    var weather: Weather?
    var emotion: Emotion?
    var earliestUnlock: Date

    // unlock state
    var unlockedAt: Date?   // nil = locked

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        geofence: Geofence? = nil,
        weather: Weather? = nil,
        emotion: Emotion? = nil,
        creationDate: Date = Date(),
        earliestUnlock: Date? = nil,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.creationDate = creationDate
        self.geofence = geofence
        self.weather = weather
        self.emotion = emotion
        self.unlockedAt = unlockedAt

        // default: creationDate + 1 day
        self.earliestUnlock = earliestUnlock ??
            Calendar.current.date(byAdding: .day, value: 1, to: creationDate)!
    }

    var isLocked: Bool {
        unlockedAt == nil
    }
}


final class StorageService: ObservableObject {
    static let shared = StorageService()

    @Published var entries: [SparkEntry] = []

    // Toggle to use API or local storage
    private let useAPI = true  // Set to false to use local storage
    private let apiClient = APIClient.shared

    private init() {}

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("sparkEntries.json")
    }

    func load() {
        if useAPI {
            Task { @MainActor in
                await loadFromAPI()
            }
        } else {
            loadFromLocal()
        }
    }
    
    @MainActor
    private func loadFromAPI() async {
        do {
            entries = try await apiClient.fetchEntries()
            print("📂 Loaded \(entries.count) entries from API")
        } catch {
            print("⚠️ Failed to load from API: \(error.localizedDescription)")
            print("📂 Falling back to local storage")
            loadFromLocal()
        }
    }
    
    private func loadFromLocal() {
        // Check if file exists
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        
        if fileExists {
            // Try to load existing data
            if let data = try? Data(contentsOf: fileURL),
               let decoded = try? JSONDecoder().decode([SparkEntry].self, from: data) {
                entries = decoded
                print("📂 Loaded \(entries.count) entries from disk")
                for (index, entry) in entries.enumerated() {
                    print("  Entry \(index): title=\(entry.title), emotion=\(entry.emotion?.rawValue ?? "nil"), weather=\(entry.weather?.rawValue ?? "nil"), geofence=\(entry.geofence != nil ? "yes" : "no")")
                }
            } else {
                // File exists but can't decode - start with empty array
                print("⚠️ Failed to decode entries, starting fresh")
                entries = []
                save()
            }
        } else {
            // No file exists - start with empty array
            print("📂 No saved file found, starting fresh")
            entries = []
        }
    }
    
    // Public method to manually create demo notes (useful for testing)
    // This will REPLACE all existing entries with demo notes
    func addDemoNotes() {
        createDemoNotes()
    }
    
    func createDemoNotes() {
        let calendar = Calendar.current
        let now = Date()
        
        // Demo note 1: Locked note with location requirement
        let demo1 = SparkEntry(
            title: "Memories from Central Park",
            content: "I remember walking through Central Park on that beautiful spring day. The cherry blossoms were in full bloom, and everything felt perfect. This note will unlock when I visit that special spot again.",
            geofence: Geofence(
                latitude: 40.7851,
                longitude: -73.9683,
                radius: 150
            ),
            creationDate: calendar.date(byAdding: .day, value: -5, to: now)!,
            earliestUnlock: calendar.date(byAdding: .day, value: -3, to: now)!
        )
        
        // Demo note 2: Unlocked note (recently unlocked)
        let demo2 = SparkEntry(
            title: "Grateful for Today",
            content: "Today was amazing! I'm feeling so grateful for all the wonderful people in my life. The weather was perfect, and I had a great time with friends.",
            emotion: .grateful,
            creationDate: calendar.date(byAdding: .day, value: -7, to: now)!,
            earliestUnlock: calendar.date(byAdding: .day, value: -6, to: now)!,
            unlockedAt: calendar.date(byAdding: .hour, value: -2, to: now)!
        )
        
        // Demo note 3: Locked note requiring rain weather
        let demo3 = SparkEntry(
            title: "Rainy Day Thoughts",
            content: "There's something peaceful about rainy days. The sound of rain against the window, a warm cup of tea, and time to reflect. This note will unlock when it's raining outside.",
            weather: .rain,
            creationDate: calendar.date(byAdding: .day, value: -3, to: now)!,
            earliestUnlock: calendar.date(byAdding: .day, value: -2, to: now)!
        )
        
        // Demo note 4: Locked note requiring happy emotion
        let demo4 = SparkEntry(
            title: "Celebration Note",
            content: "I want to capture this moment of pure joy! When I'm feeling happy again, I'll be able to read this and remember what made me smile today.",
            emotion: .happy,
            creationDate: calendar.date(byAdding: .day, value: -10, to: now)!,
            earliestUnlock: calendar.date(byAdding: .day, value: -9, to: now)!
        )
        
        // Demo note 5: Locked note with multiple conditions (location + weather)
        let demo5 = SparkEntry(
            title: "Beach Sunset Memory",
            content: "The perfect beach sunset - clear skies, warm sand, and the sound of waves. This memory is locked until I'm at the beach on a clear day again.",
            geofence: Geofence(
                latitude: 34.0522,
                longitude: -118.2437,
                radius: 200
            ),
            weather: .clear,
            creationDate: calendar.date(byAdding: .day, value: -14, to: now)!,
            earliestUnlock: calendar.date(byAdding: .day, value: -12, to: now)!
        )
        
        // Demo note 6: Unlocked note (older)
        let demo6 = SparkEntry(
            title: "Morning Reflection",
            content: "Early mornings have become my favorite time. The quiet, the coffee, the sense of possibility. This note was unlocked yesterday and I'm glad I can read it now.",
            creationDate: calendar.date(byAdding: .day, value: -20, to: now)!,
            earliestUnlock: calendar.date(byAdding: .day, value: -19, to: now)!,
            unlockedAt: calendar.date(byAdding: .day, value: -1, to: now)!
        )
        
        // Demo note 7: Locked note requiring snow
        let demo7 = SparkEntry(
            title: "Winter Wonderland",
            content: "Snow days are magical. Everything is quiet, peaceful, and beautiful. This note will unlock when it snows, bringing back memories of winter adventures.",
            weather: .snow,
            creationDate: calendar.date(byAdding: .day, value: -2, to: now)!,
            earliestUnlock: calendar.date(byAdding: .day, value: -1, to: now)!
        )
        
        // Demo note 8: Locked note with all conditions (location + weather + emotion)
        let demo8 = SparkEntry(
            title: "Perfect Day Memory",
            content: "Everything aligned perfectly that day - the location, the weather, and my mood. This note captures that perfect moment and will only unlock when all those conditions are met again.",
            geofence: Geofence(
                latitude: 37.7749,
                longitude: -122.4194,
                radius: 150
            ),
            weather: .partlyCloudy,
            emotion: .calm,
            creationDate: calendar.date(byAdding: .day, value: -8, to: now)!,
            earliestUnlock: calendar.date(byAdding: .day, value: -6, to: now)!
        )
        
        // Demo note 9: Simple locked note (no special conditions, just time-based)
        let demo9 = SparkEntry(
            title: "Future Me",
            content: "Hey future me! I'm writing this note today, and it will unlock tomorrow. I wonder what I'll be thinking when I read this. Time will tell!",
            creationDate: calendar.date(byAdding: .hour, value: -12, to: now)!,
            earliestUnlock: calendar.date(byAdding: .hour, value: 12, to: now)!
        )
        
        // Demo note 10: Recently unlocked note
        let demo10 = SparkEntry(
            title: "Quick Note",
            content: "Just a quick thought I wanted to capture. This note unlocked recently and I'm reading it now. Sometimes the simplest notes are the most meaningful.",
            emotion: .excited,
            creationDate: calendar.date(byAdding: .day, value: -4, to: now)!,
            earliestUnlock: calendar.date(byAdding: .day, value: -3, to: now)!,
            unlockedAt: calendar.date(byAdding: .hour, value: -5, to: now)!
        )
        
        entries = [demo1, demo2, demo3, demo4, demo5, demo6, demo7, demo8, demo9, demo10]
        save()
    }

    func save() {
        if useAPI {
            // API saves are handled individually in add/update/delete
            return
        }
        
        print("💾 Saving \(entries.count) entries to disk")
        for (index, entry) in entries.enumerated() {
            print("  Entry \(index): title=\(entry.title), emotion=\(entry.emotion?.rawValue ?? "nil"), weather=\(entry.weather?.rawValue ?? "nil"), geofence=\(entry.geofence != nil ? "yes" : "no")")
        }
        
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
            print("✅ Saved successfully to \(fileURL.path)")
        } else {
            print("❌ Failed to encode entries")
        }
    }

    func add(_ entry: SparkEntry) {
        if useAPI {
            Task {
                await addToAPI(entry)
            }
        } else {
        entries.append(entry)
        save()
        }
    }
    
    @MainActor
    private func addToAPI(_ entry: SparkEntry) async {
        do {
            let createdEntry = try await apiClient.createEntry(entry)
            entries.append(createdEntry)
            print("✅ Created entry via API: \(createdEntry.title)")
        } catch {
            print("❌ Failed to create entry via API: \(error.localizedDescription)")
            // Fallback to local
            entries.append(entry)
            save()
        }
    }

    func update(_ entry: SparkEntry) {
        if useAPI {
            Task {
                await updateInAPI(entry)
            }
        } else {
            if let i = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[i] = entry
                save()
            }
        }
    }
    
    @MainActor
    private func updateInAPI(_ entry: SparkEntry) async {
        do {
            print("🔄 Updating entry via API: \(entry.title) (ID: \(entry.id.uuidString))")
            let updatedEntry = try await apiClient.updateEntry(entry)
            if let i = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[i] = updatedEntry
                print("✅ Updated entry via API: \(updatedEntry.title)")
            } else {
                print("⚠️ Entry not found in local array after API update")
            }
        } catch {
            print("❌ Failed to update entry via API: \(error.localizedDescription)")
            print("   Entry ID: \(entry.id.uuidString)")
            print("   Entry title: \(entry.title)")
            // Fallback to local
            if let i = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[i] = entry
                save()
            }
        }
    }
    
    func delete(_ entry: SparkEntry) {
        if useAPI {
            Task {
                await deleteFromAPI(entry)
            }
        } else {
            entries.removeAll { $0.id == entry.id }
            save()
        }
    }
    
    @MainActor
    private func deleteFromAPI(_ entry: SparkEntry) async {
        do {
            try await apiClient.deleteEntry(id: entry.id)
            entries.removeAll { $0.id == entry.id }
            print("✅ Deleted entry via API: \(entry.title)")
        } catch {
            print("❌ Failed to delete entry via API: \(error.localizedDescription)")
            // Fallback to local
            entries.removeAll { $0.id == entry.id }
            save()
        }
    }
    
    func clearAll() {
        entries = []
        if !useAPI {
        save()
        }
    }
}
