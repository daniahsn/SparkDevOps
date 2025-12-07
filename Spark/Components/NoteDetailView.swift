//
//  NoteDetailView.swift
//  Spark
//
//  Detailed view for displaying a full note
//

import SwiftUI
import MapKit

struct NoteDetailView: View {
    let entry: SparkEntry
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with back button and centered title
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(BrandStyle.accent)
                    }
                    
                    Spacer()
                    
                    Text(entry.title)
                        .font(BrandStyle.title)
                        .foregroundColor(BrandStyle.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Invisible spacer to balance the back button
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Status Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: entry.isLocked ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 20))
                            .foregroundColor(entry.isLocked ? .orange : .green)
                        
                        Text(entry.isLocked ? "Waiting" : "Unlocked")
                            .font(BrandStyle.caption)
                            .foregroundColor(entry.isLocked ? .orange : .green)
                        
                        Spacer()
                    }
                    
                    Text("Created: \(entry.creationDate, style: .date)")
                        .font(BrandStyle.caption)
                        .foregroundColor(BrandStyle.textSecondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(BrandStyle.accent, lineWidth: 1.5)
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Content (only show if unlocked)
                if entry.isLocked {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40))
                            .foregroundColor(BrandStyle.accent.opacity(0.5))
                        
                        Text("This memory is waiting")
                            .font(BrandStyle.sectionTitle)
                            .foregroundColor(BrandStyle.textPrimary)
                        
                        Text("Experience the moments you set to retrieve this memory")
                            .font(BrandStyle.body)
                            .foregroundColor(BrandStyle.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BrandStyle.accent, lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                } else {
                    Text(entry.content)
                        .font(BrandStyle.body)
                        .foregroundColor(BrandStyle.textPrimary)
                        .lineSpacing(4)
                        .padding(.horizontal)
                }
                
                // Lock Conditions Section
                if hasAnyLockConditions {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Memory Triggers")
                            .font(BrandStyle.sectionTitle)
                            .foregroundColor(BrandStyle.textPrimary)
                            .padding(.horizontal)
                        
                        // Location condition
                        if let geofence = entry.geofence {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(BrandStyle.accent)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("When you are at this place again")
                                        .font(BrandStyle.body)
                                        .foregroundColor(BrandStyle.textPrimary)
                                    Text("Within \(Int(geofence.radius))m of this location")
                                        .font(BrandStyle.caption)
                                        .foregroundColor(BrandStyle.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(BrandStyle.accent, lineWidth: 1.5)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Weather condition
                        if let weather = entry.weather {
                            HStack(spacing: 12) {
                                WeatherIcon(weather: weather)
                                    .font(.system(size: 24))
                                    .foregroundColor(BrandStyle.accent)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("When this weather returns")
                                        .font(BrandStyle.body)
                                        .foregroundColor(BrandStyle.textPrimary)
                                    Text(weather.displayName)
                                        .font(BrandStyle.caption)
                                        .foregroundColor(BrandStyle.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(BrandStyle.accent, lineWidth: 1.5)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Emotion condition
                        if let emotion = entry.emotion {
                            HStack(spacing: 12) {
                                Image(systemName: emotionIcon(emotion))
                                    .font(.system(size: 24))
                                    .foregroundColor(BrandStyle.accent)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("When you feel this way again")
                                        .font(BrandStyle.body)
                                        .foregroundColor(BrandStyle.textPrimary)
                                    Text(emotion.rawValue.capitalized)
                                        .font(BrandStyle.caption)
                                        .foregroundColor(BrandStyle.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(BrandStyle.accent, lineWidth: 1.5)
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var hasAnyLockConditions: Bool {
        entry.geofence != nil || entry.weather != nil || entry.emotion != nil
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

#Preview {
    NavigationStack {
        NoteDetailView(
            entry: SparkEntry(
                title: "My First Memory",
                content: "This is a detailed view of a memory. It shows all the information about the memory including its lock conditions and status.",
                geofence: Geofence(latitude: 37.7749, longitude: -122.4194, radius: 150),
                weather: .rain,
                emotion: .happy
            )
        )
    }
}

