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

struct SparkEntry: Identifiable, Codable {
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

    private init() {}

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("sparkEntries.json")
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([SparkEntry].self, from: data)
        else { return }

        entries = decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func add(_ entry: SparkEntry) {
        entries.append(entry)
        save()
    }

    func update(_ entry: SparkEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = entry
            save()
        }
    }
}
