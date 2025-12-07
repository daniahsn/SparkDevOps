import SwiftUI

struct EmotionLockView: View {
    @EnvironmentObject var storage: StorageService

    // Data passed from CreateView
    let title: String
    let content: String
    @Binding var geofence: Geofence?
    @Binding var weather: Weather?

    // Bind back to CreateView
    @Binding var emotion: Emotion?
    @Binding var path: NavigationPath

    @State private var selectedEmotion: Emotion? = nil

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Spark")
                    .font(BrandStyle.title)
                    .foregroundColor(BrandStyle.accent)
                Text("Emotion Trigger")
                    .font(BrandStyle.sectionTitle)
                    .foregroundColor(BrandStyle.textPrimary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            // ------- Explanation -------
            Text("Select the feeling that will unlock this memory when you experience it again.")
                .font(BrandStyle.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // ------- Emotion Matrix -------
            VStack(spacing: 12) {
                let columns = [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ]
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Emotion.allCases, id: \.self) { emo in
                        EmotionChip(
                            emotion: emo,
                            isSelected: selectedEmotion == emo,
                            onTap: { selectedEmotion = emo }
                        )
                    }
                }
                
                // Clear Selection Button
                Button { 
                    selectedEmotion = nil 
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Clear Selection")
                            .font(BrandStyle.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BrandStyle.accent, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(BrandStyle.accent)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            VStack(spacing: 12) {

                // Skip
                Button {
                    emotion = nil
                    saveEntryHere()
                    path.append(CreateFlowStep.finish)
                } label: {
                    Text("Skip Emotion")
                        .font(BrandStyle.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(12)
                }

                // Use Emotion
                Button {
                    if let emo = selectedEmotion {
                        emotion = emo
                        saveEntryHere()
                        path.append(CreateFlowStep.finish)
                    }
                } label: {
                    Text("Use Emotion")
                        .font(BrandStyle.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedEmotion != nil ? BrandStyle.accent : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(selectedEmotion == nil)
            }
        }
        .padding()
        .onAppear {
            // Re-sync if user returns back
            selectedEmotion = emotion
        }
    }

    // MARK: - Save Entry Right Here (Option B)
    private func saveEntryHere() {
        let entry = SparkEntry(
            title: title,
            content: content,
            geofence: geofence,
            weather: weather,
            emotion: selectedEmotion,  // nil if skipped
            creationDate: Date(),
            unlockedAt: nil
        )

        storage.add(entry)
    }
}


// MARK: - Emotion Chip
private struct EmotionChip: View {
    let emotion: Emotion
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium))
                Text(emotion.rawValue.capitalized)
                    .font(BrandStyle.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? BrandStyle.accent : BrandStyle.accent.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(isSelected ? BrandStyle.accent : BrandStyle.textPrimary)
        }
        .buttonStyle(.plain)
    }
    
    private var iconName: String {
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

