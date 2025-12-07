//
//  NoteCardView.swift
//  Spark
//
//  Modular note card view for use in search results and homepage
//

import SwiftUI

struct NoteCardView: View {
    let entry: SparkEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            // Only allow navigation if note is unlocked
            if !entry.isLocked {
                onTap()
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {

                // Header with lock status
                HStack(alignment: .center) {

                    // Lock status badge
                    HStack(spacing: 6) {
                        Image(systemName: entry.isLocked ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(entry.isLocked ? "Waiting" : "Unlocked")
                            .font(BrandStyle.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(BrandStyle.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        BrandStyle.accent.opacity(0.15)
                    )
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Date created
                    Text(entry.creationDate, style: .date)
                        .font(BrandStyle.caption)
                        .foregroundColor(BrandStyle.textSecondary)
                }

                // Title
                Text(entry.title)
                    .font(BrandStyle.sectionTitle)
                    .foregroundColor(BrandStyle.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Content preview (only show if unlocked)
                if entry.isLocked {
                    Text("This memory awaits its moment. Experience the triggers you set to retrieve it.")
                        .font(BrandStyle.body)
                        .foregroundColor(BrandStyle.textSecondary.opacity(0.7))
                        .italic()
                        .lineLimit(2)
                } else {
                    Text(entry.content)
                        .font(BrandStyle.body)
                        .foregroundColor(BrandStyle.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Lock conditions badges
                if entry.geofence != nil || entry.weather != nil || entry.emotion != nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {

                            if entry.geofence != nil {
                                ConditionBadge(
                                    icon: "mappin.circle.fill",
                                    text: "Location",
                                    color: BrandStyle.accent
                                )
                            }
                            
                            if let w = entry.weather {
                                ConditionBadge(
                                    icon: weatherIconName(w),
                                    text: w.displayName,
                                    color: BrandStyle.accent
                                )
                            }
                            
                            if let emo = entry.emotion {
                                ConditionBadge(
                                    icon: emotionIcon(emo),
                                    text: emo.rawValue.capitalized,
                                    color: BrandStyle.accent
                                )
                            }
                        }
                    }
                }

                // Unlock info (only if unlocked)
                if let unlockedAt = entry.unlockedAt {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(BrandStyle.accent)

                        Text("Unlocked: \(unlockedAt, style: .relative)")
                            .font(BrandStyle.caption)
                            .foregroundColor(BrandStyle.textSecondary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(BrandStyle.accent, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func weatherIconName(_ weather: Weather) -> String {
        switch weather {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .freezingRain: return "cloud.sleet.fill"
        case .snow: return "cloud.snow.fill"
        case .hail: return "snowflake"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private func emotionIcon(_ emotion: Emotion) -> String {
        switch emotion {
        case .happy: return "face.smiling"
        case .sad: return "face.dashed"
        case .angry: return "flame.fill"
        case .relaxed: return "leaf.fill"
        case .excited: return "bolt.fill"
        case .stressed: return "exclamationmark.triangle.fill"
        case .bored: return "hourglass"
        case .anxious: return "aqi.low"
        case .grateful: return "hands.sparkles.fill"
        case .calm: return "wind"
        case .energetic: return "figure.run"
        case .tired: return "zzz"
        }
    }
}

// MARK: - Condition Badge Component
struct ConditionBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(text)
                .font(BrandStyle.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        NoteCardView(
            entry: SparkEntry(
                title: "My First Memory",
                content: "This is a sample memory with some content that might be longer than expected.",
                geofence: Geofence(latitude: 37.7749, longitude: -122.4194, radius: 150),
                weather: .rain,
                emotion: .happy
            ),
            onTap: {}
        )
        
        NoteCardView(
            entry: SparkEntry(
                title: "Retrieved Memory",
                content: "This memory has been unlocked and can be read.",
                unlockedAt: Date()
            ),
            onTap: {}
        )
    }
    .padding()
    .background(BrandStyle.background)
}
