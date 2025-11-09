//
//  LockAndUnlockTracking.swift
//  Spark
//
//  Created by Julius  Jung on 03.11.2025.
//

import SwiftUI
import Combine

// MARK: - Models

enum UnlockTrigger: String, Codable, CaseIterable {
    case location = "location"
    case weather = "weather"
    case mood = "mood"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .location: return "location.fill"
        case .weather: return "cloud.sun.fill"
        case .mood: return "face.smiling.fill"
        }
    }
}

// Journal Entry that can be unlocked by multiple triggers
struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let createdAt: Date                      // Order entries by creation time
    var isLocked: Bool
    let possibleTriggers: Set<UnlockTrigger> // Which triggers CAN unlock this entry
    var unlockedBy: UnlockTrigger?           // Which trigger ACTUALLY unlocked it
    var unlockedAt: Date?                    // When it was unlocked
    
    init(id: UUID = UUID(), title: String, content: String, createdAt: Date = Date(), possibleTriggers: Set<UnlockTrigger>) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.isLocked = true
        self.possibleTriggers = possibleTriggers
        self.unlockedBy = nil
        self.unlockedAt = nil
    }
}

// History event linking entry to trigger
struct UnlockEvent: Identifiable, Codable {
    let id: UUID
    let entryId: UUID
    let entryTitle: String
    let timestamp: Date
    let trigger: UnlockTrigger
    
    init(id: UUID = UUID(), entryId: UUID, entryTitle: String, timestamp: Date = Date(), trigger: UnlockTrigger) {
        self.id = id
        self.entryId = entryId
        self.entryTitle = entryTitle
        self.timestamp = timestamp
        self.trigger = trigger
    }
}

// MARK: - Manager

class UnlockManager: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var unlockHistory: [UnlockEvent] = []
    
    private let entriesKey = "spark.entries"
    private let historyKey = "spark.unlockHistory"
    
    init() {
        loadData()
        
        // Create demo entries if none exist
        if entries.isEmpty {
            createDemoEntries()
        }
    }
    
    private func createDemoEntries() {
        let now = Date()
        
        // Create entries with different timestamps (older to newer)
        // Entry 1: Oldest - Can be unlocked by location OR weather
        entries.append(JournalEntry(
            title: "Coffee Shop Memory",
            content: "That rainy afternoon at the downtown coffee shop, where everything felt perfect. The smell of fresh espresso, the sound of rain on the windows, and a good book in my hands.",
            createdAt: now.addingTimeInterval(-86400 * 7), // 7 days ago
            possibleTriggers: [.location, .weather]
        ))
        
        // Entry 2: Can be unlocked by location (shares trigger with Entry 1)
        entries.append(JournalEntry(
            title: "Downtown Adventure",
            content: "Exploring the city streets, discovering hidden alleys and local gems. Every corner held a new surprise.",
            createdAt: now.addingTimeInterval(-86400 * 5), // 5 days ago
            possibleTriggers: [.location]
        ))
        
        // Entry 3: Can be unlocked by mood OR weather
        entries.append(JournalEntry(
            title: "Sunset Walk",
            content: "Walking along the beach at sunset, feeling grateful and peaceful. The golden light, the gentle breeze, and a heart full of contentment.",
            createdAt: now.addingTimeInterval(-86400 * 3), // 3 days ago
            possibleTriggers: [.mood, .weather]
        ))
        
        // Entry 4: Can be unlocked by location (most recent with location trigger)
        entries.append(JournalEntry(
            title: "The Park Bench",
            content: "Sitting on that old park bench, watching the world go by. A moment of peace in a busy life.",
            createdAt: now.addingTimeInterval(-86400 * 2), // 2 days ago
            possibleTriggers: [.location, .mood]
        ))
        
        // Entry 5: Can be unlocked by ANY trigger
        entries.append(JournalEntry(
            title: "Life-Changing Moment",
            content: "A memory so powerful that it can be unlocked by being in the right place, the right weather, or the right emotional state. This is where everything changed.",
            createdAt: now.addingTimeInterval(-86400), // 1 day ago
            possibleTriggers: [.location, .weather, .mood]
        ))
        
        // Entry 6: Most recent - Only weather
        entries.append(JournalEntry(
            title: "First Snow",
            content: "The first snowfall of winter. Everything was quiet, peaceful, and magical.",
            createdAt: now, // Today
            possibleTriggers: [.weather]
        ))
        
        saveData()
    }
    
    // Simulate a TRIGGER - unlocks the most recent locked entry that can be unlocked by it
    func simulateTrigger(_ trigger: UnlockTrigger) {
        // Find all locked entries that can be unlocked by this trigger
        let matchingEntries = entries.filter { entry in
            entry.isLocked && entry.possibleTriggers.contains(trigger)
        }
        
        // Sort by createdAt (most recent first) and get the first one
        guard let mostRecentEntry = matchingEntries.sorted(by: { $0.createdAt > $1.createdAt }).first else {
            print("❌ No locked entries can be unlocked with \(trigger.displayName) trigger")
            return
        }
        
        // Unlock it
        unlockEntry(mostRecentEntry, with: trigger)
    }
    
    // Unlock a SPECIFIC entry with a specific trigger (manual selection)
    func unlockEntry(_ entry: JournalEntry, with trigger: UnlockTrigger) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        
        // Check if this trigger can unlock this entry
        guard entry.possibleTriggers.contains(trigger) else {
            print("❌ Cannot unlock '\(entry.title)' with \(trigger.displayName) trigger")
            return
        }
        
        // Unlock the entry
        entries[index].isLocked = false
        entries[index].unlockedBy = trigger
        entries[index].unlockedAt = Date()
        
        // Create history event
        let event = UnlockEvent(
            entryId: entry.id,
            entryTitle: entry.title,
            trigger: trigger
        )
        unlockHistory.insert(event, at: 0) // Most recent first
        
        saveData()
    }
    
    // Get the most recent unlock event
    var currentUnlock: UnlockEvent? {
        unlockHistory.first
    }
    
    // Get all unlocked entries
    var unlockedEntries: [JournalEntry] {
        entries.filter { !$0.isLocked }
    }
    
    // Get all locked entries
    var lockedEntries: [JournalEntry] {
        entries.filter { $0.isLocked }
    }
    
    private func saveData() {
        if let entriesData = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(entriesData, forKey: entriesKey)
        }
        if let historyData = try? JSONEncoder().encode(unlockHistory) {
            UserDefaults.standard.set(historyData, forKey: historyKey)
        }
    }
    
    private func loadData() {
        if let entriesData = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([JournalEntry].self, from: entriesData) {
            entries = decoded
        }
        
        if let historyData = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([UnlockEvent].self, from: historyData) {
            unlockHistory = decoded
        }
    }
    
    // Reset to demo state
    func resetDemo() {
        entries.removeAll()
        unlockHistory.removeAll()
        createDemoEntries()
    }
}

// MARK: - Views

struct LockAndUnlockTracking: View {
    @StateObject private var manager = UnlockManager()
    @State private var selectedEntry: JournalEntry?
    @State private var showingTriggerPicker = false
    
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
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Current Status Section
                        currentStatusSection
                        
                        // Trigger Simulation Section
                        triggerSimulationSection
                        
                        // Journal Entries Section
                        journalEntriesSection
                        
                        // History Section
                        historySection
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Lock & Unlock Tracking")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        manager.resetDemo()
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
            .sheet(isPresented: $showingTriggerPicker) {
                if let entry = selectedEntry {
                    TriggerPickerSheet(entry: entry, manager: manager, isPresented: $showingTriggerPicker)
                }
            }
        }
    }
    
    // MARK: - Current Status
    
    private var currentStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lock.shield")
                    .font(SparkFont.ui(20, weight: .semibold))
                    .foregroundColor(.brandAccent)
                Text("Current Status")
                    .font(SparkFont.ui(24, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            
            if let unlock = manager.currentUnlock {
                UnlockStatusCard(event: unlock)
            } else {
                EmptyStatusCard()
            }
        }
    }
    
    // MARK: - Trigger Simulation
    
    private var triggerSimulationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(SparkFont.ui(20, weight: .semibold))
                    .foregroundColor(.brandAccent)
                Text("Simulate Triggers")
                    .font(SparkFont.ui(24, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            
            Text("Tap a trigger to unlock the most recent entry that can be unlocked by it")
                .font(SparkFont.ui(14, weight: .regular))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(UnlockTrigger.allCases, id: \.self) { trigger in
                    TriggerSimulationButton(
                        trigger: trigger,
                        lockedCount: manager.entries.filter { $0.isLocked && $0.possibleTriggers.contains(trigger) }.count
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            manager.simulateTrigger(trigger)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Journal Entries
    
    private var journalEntriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "book.fill")
                    .font(SparkFont.ui(20, weight: .semibold))
                    .foregroundColor(.brandAccent)
                Text("Journal Entries")
                    .font(SparkFont.ui(24, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(manager.entries) { entry in
                    JournalEntryCard(entry: entry) {
                        selectedEntry = entry
                        showingTriggerPicker = true
                    }
                }
            }
        }
    }
    
    // MARK: - History
    
    private var historySection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(SparkFont.ui(20, weight: .semibold))
                    .foregroundColor(.brandAccent)
                Text("Unlock History")
                    .font(SparkFont.ui(24, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            
            if manager.unlockHistory.isEmpty {
                EmptyHistoryCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(manager.unlockHistory) { event in
                        HistoryRow(event: event)
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

// Journal Entry Card - shows which triggers can unlock it
struct JournalEntryCard: View {
    let entry: JournalEntry
    let onTapUnlock: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(SparkFont.ui(20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Status badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(entry.isLocked ? Color.brandAccent : Color.brandSecondary)
                            .frame(width: 8, height: 8)
                        
                        Text(entry.isLocked ? "LOCKED" : "UNLOCKED")
                            .font(SparkFont.ui(13, weight: .bold))
                            .foregroundColor(entry.isLocked ? .brandAccent : .brandSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(entry.isLocked ? Color.brandAccent.opacity(0.1) : Color.brandSecondary.opacity(0.15))
                    )
                }
                
                Spacer()
                
                // Lock icon
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
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: entry.isLocked ? "lock.fill" : "lock.open.fill")
                        .font(SparkFont.ui(24, weight: .semibold))
                        .foregroundColor(entry.isLocked ? .brandAccent : .brandSecondary)
                }
            }
            .padding(20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Possible Triggers
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(SparkFont.ui(14, weight: .semibold))
                        .foregroundColor(.brandAccent)
                    Text("Can be unlocked by")
                        .font(SparkFont.ui(13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.3)
                }
                
                HStack(spacing: 8) {
                    ForEach(Array(entry.possibleTriggers.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { trigger in
                        HStack(spacing: 6) {
                            Image(systemName: trigger.icon)
                                .font(SparkFont.ui(12, weight: .medium))
                            Text(trigger.displayName)
                                .font(SparkFont.ui(13, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.brandAccent.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(20)
            .padding(.top, 4)
            
            // If unlocked, show unlock info
            if !entry.isLocked, let unlockedBy = entry.unlockedBy, let unlockedAt = entry.unlockedAt {
                Divider()
                    .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(SparkFont.ui(16, weight: .semibold))
                        .foregroundColor(.brandSecondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlocked via \(unlockedBy.displayName)")
                            .font(SparkFont.ui(14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(formattedDate(unlockedAt))
                            .font(SparkFont.ui(12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(20)
                .background(Color.brandSecondary.opacity(0.08))
            } else {
                // Unlock button for locked entries
                Button(action: onTapUnlock) {
                    HStack {
                        Text("Simulate Unlock")
                            .font(SparkFont.ui(15, weight: .semibold))
                            .foregroundColor(.brandAccent)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(SparkFont.ui(14, weight: .semibold))
                            .foregroundColor(.brandAccent)
                    }
                    .padding(20)
                    .background(Color.brandAccent.opacity(0.05))
                }
                .buttonStyle(.plain)
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}

// Trigger Picker Sheet
struct TriggerPickerSheet: View {
    let entry: JournalEntry
    @ObservedObject var manager: UnlockManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.brandDominant, Color.brandSecondary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Entry info
                    VStack(spacing: 12) {
                        Text(entry.title)
                            .font(SparkFont.ui(24, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Select a trigger to unlock this entry")
                            .font(SparkFont.ui(15, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Trigger buttons
                    VStack(spacing: 12) {
                        ForEach(Array(entry.possibleTriggers.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { trigger in
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    manager.unlockEntry(entry, with: trigger)
                                    isPresented = false
                                }
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.brandAccent.opacity(0.2), Color.brandAccent.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: trigger.icon)
                                            .font(SparkFont.ui(20, weight: .semibold))
                                            .foregroundColor(.brandAccent)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Unlock with \(trigger.displayName)")
                                            .font(SparkFont.ui(16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text("Simulate \(trigger.displayName) trigger")
                                            .font(SparkFont.ui(13, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
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
                                        .stroke(Color.brandAccent.opacity(0.2), lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Select Trigger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.brandAccent)
                }
            }
        }
    }
}

struct UnlockStatusCard: View {
    let event: UnlockEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with unlock icon
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Latest Unlock")
                        .font(SparkFont.ui(26, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Status badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.brandSecondary)
                            .frame(width: 8, height: 8)
                        
                        Text("RECENT")
                            .font(SparkFont.ui(13, weight: .bold))
                            .foregroundColor(.brandSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.brandSecondary.opacity(0.15))
                    )
                }
                
                Spacer()
                
                // Lock icon with animated background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brandSecondary.opacity(0.3), Color.brandSecondary.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "lock.open.fill")
                        .font(SparkFont.ui(28, weight: .semibold))
                        .foregroundColor(.brandSecondary)
                }
            }
            .padding(20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Entry title
            VStack(alignment: .leading, spacing: 8) {
                Text("ENTRY")
                    .font(SparkFont.ui(12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
                
                Text(event.entryTitle)
                    .font(SparkFont.ui(18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Timestamp section
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(SparkFont.ui(16, weight: .semibold))
                    .foregroundColor(.brandSecondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlocked on \(formattedDate(event.timestamp)) because of \(event.trigger.displayName)")
                        .font(SparkFont.ui(14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color.brandSecondary.opacity(0.08))
        }
        .background(Color.brandDominant)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.brandSecondary.opacity(0.4), lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}

struct EmptyStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Locked")
                        .font(SparkFont.ui(26, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Status badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.brandAccent)
                            .frame(width: 8, height: 8)
                        
                        Text("LOCKED")
                            .font(SparkFont.ui(13, weight: .bold))
                            .foregroundColor(.brandAccent)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.brandAccent.opacity(0.1))
                    )
                }
                
                Spacer()
                
                // Lock icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brandAccent.opacity(0.2), Color.brandAccent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "lock.fill")
                        .font(SparkFont.ui(28, weight: .semibold))
                        .foregroundColor(.brandAccent)
                }
            }
            .padding(20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Message
            VStack(spacing: 8) {
                Text("No recent unlocks")
                    .font(SparkFont.ui(16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Unlock a journal entry to see it here")
                    .font(SparkFont.ui(14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .background(Color.brandDominant)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.brandAccent.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }
}

struct HistoryRow: View {
    let event: UnlockEvent
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon circle with trigger icon
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
                
                Image(systemName: event.trigger.icon)
                    .font(SparkFont.ui(18, weight: .semibold))
                    .foregroundColor(.brandSecondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.entryTitle)
                    .font(SparkFont.ui(16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "key.fill")
                            .font(SparkFont.ui(10, weight: .medium))
                        Text(event.trigger.displayName)
                    }
                    .font(SparkFont.ui(12, weight: .medium))
                    .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(SparkFont.ui(10, weight: .medium))
                        Text(formattedDate(event.timestamp))
                    }
                    .font(SparkFont.ui(12, weight: .regular))
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}

struct EmptyHistoryCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandAccent.opacity(0.15), Color.brandAccent.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "clock.fill")
                    .font(SparkFont.ui(32, weight: .semibold))
                    .foregroundColor(.brandAccent)
            }
            
            VStack(spacing: 6) {
                Text("No unlock history yet")
                    .font(SparkFont.ui(18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Unlock triggers will appear here")
                    .font(SparkFont.ui(14, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(Color.brandDominant)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.brandAccent.opacity(0.2), lineWidth: 1.5)
        )
        .padding(.horizontal, 20)
    }
}

// Trigger Simulation Button - shows how many entries can be unlocked
struct TriggerSimulationButton: View {
    let trigger: UnlockTrigger
    let lockedCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brandAccent.opacity(0.2), Color.brandAccent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: trigger.icon)
                        .font(SparkFont.ui(20, weight: .semibold))
                        .foregroundColor(.brandAccent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fire \(trigger.displayName) Trigger")
                        .font(SparkFont.ui(16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if lockedCount > 0 {
                        Text("\(lockedCount) locked \(lockedCount == 1 ? "entry" : "entries") available")
                            .font(SparkFont.ui(13, weight: .regular))
                            .foregroundColor(.brandSecondary)
                    } else {
                        Text("No locked entries available")
                            .font(SparkFont.ui(13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if lockedCount > 0 {
                    // Badge showing count
                    ZStack {
                        Circle()
                            .fill(Color.brandSecondary)
                            .frame(width: 28, height: 28)
                        
                        Text("\(lockedCount)")
                            .font(SparkFont.ui(14, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "lock.slash")
                        .font(SparkFont.ui(16, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(16)
            .background(Color.brandDominant)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        lockedCount > 0 ?
                            Color.brandAccent.opacity(0.3) :
                            Color.secondary.opacity(0.2),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .disabled(lockedCount == 0)
        .opacity(lockedCount > 0 ? 1.0 : 0.6)
    }
}

// MARK: - Preview

#Preview {
    LockAndUnlockTracking()
}
