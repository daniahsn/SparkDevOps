//
//  EmotionTrigger.swift
//  Spark
//
//  Created by Julius  Jung on 03.11.2025.
//

import SwiftUI

struct Brand {
    static let dominant = Color(hex: "#FFFFFF")
    static let accent = Color(hex: "#FF8D28")
    static let secondary = Color(hex: "#FFCC02")
}

extension Color {
    init(hex: String, opacity: Double = 1.0) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") {s.removeFirst()}
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

enum Mood: String, CaseIterable, Identifiable {
    case happy = "Happy"
    case sad = "Sad"
    case calm = "Calm"
    case excited = "Excited"
    
    var id: String { rawValue }
    
    var systemName: String {
        switch self {
        case .happy: return "face.smiling"
        case .sad: return "cloud.rain"
        case .calm: return "wind"
        case .excited: return "sparkles"
        }
    }
}

struct MoodEntry: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let requiredMood: Mood
}

struct MoodChip: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: mood.systemName)
                    .font(.system(size: 16, weight: .regular))
                Text(mood.rawValue)
                    .font(SparkFont.ui(14))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Brand.accent.opacity(0.18)
                        : Brand.secondary.opacity(0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Brand.accent : Brand.secondary, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.black)
        }
        .buttonStyle(.plain)
    }
}

struct MoodEntryCard: View {
    let entry: MoodEntry
    let selectedMood: Mood?
    
    private var isUnlocked: Bool { selectedMood == entry.requiredMood }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(entry.title)
                    .font(SparkFont.ui(18))
                Spacer()
                Image(systemName: entry.requiredMood.systemName)
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.8))
                Image(systemName: isUnlocked ? "lock.open" : "lock")
                    .font(.system(size: 18))
                    .foregroundColor(isUnlocked ? Brand.accent : .black)
            }
            HStack {
                Text(isUnlocked ? "Unlocked" : "Locked")
                    .font(SparkFont.ui(14))
                    .foregroundColor(.black)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: entry.requiredMood.systemName)
                    Text(entry.requiredMood.rawValue)
                }
                .font(SparkFont.ui(13))
                .foregroundColor(.black.opacity(0.7))
            }
            
            Button {
            } label: {
                Text(isUnlocked ? "READ ENTRY" : "LOCKED")
                    .font(SparkFont.ui(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isUnlocked ? Brand.accent : Brand.secondary.opacity(0.6))
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!isUnlocked)
        }
        .padding(14)
        .background(Brand.secondary.opacity(0.22))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct EmotionTrigger: View {
    @State private var selectedMood: Mood? = nil
    @State private var entries: [MoodEntry] = [
        .init(title: "Morning Run", date: "1/1/25", requiredMood: .calm),
        .init(title: "Concert Night", date: "5/29/25", requiredMood: .excited),
        .init(title: "Hard Exam Day", date: "7/23/25", requiredMood: .sad),
        .init(title: "Lunch with Mom", date: "9/25/25", requiredMood: .happy)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Spark.")
                        .font(SparkFont.logo(34))
                        .foregroundColor(Brand.accent)
                    Text("Emotion Unlock")
                        .font(SparkFont.ui(18))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pick your mood")
                        .font(SparkFont.ui(16))
                        .foregroundColor(.black)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Mood.allCases) { mood in
                            MoodChip(
                                mood: mood,
                                isSelected: selectedMood == mood,
                                onTap: {
                                    withAnimation(.spring(response: 0.25)) {
                                        selectedMood = mood
                                    }
                                }
                            )
                        }
                        
                    }
                }
                if let m = selectedMood {
                    HStack(spacing: 6) {
                        Image(systemName: m.systemName)
                            .font(.system(size: 14))
                        Text("Selected: \(m.rawValue)")
                            .font(SparkFont.ui(13))
                    }
                    .foregroundColor(.black.opacity(0.8))
                } else {
                    Text("Select a mood to try unlocking entries.")
                        .font(SparkFont.ui(13))
                        .foregroundColor(.black.opacity(0.8))
                }
                VStack(alignment: .leading, spacing: 14) {
                    Text("Entries")
                        .font(SparkFont.ui(16))
                        .foregroundColor(.black)
                    ForEach(entries) { entry in
                        MoodEntryCard(entry: entry, selectedMood: selectedMood)
                    }
                }
            }
            .padding(20)
        }
            .background(Brand.dominant.ignoresSafeArea())
    }
}

#Preview {
    EmotionTrigger()
}
