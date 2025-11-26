import SwiftUI

struct EmotionLockView: View {

    let title: String
    let content: String
    let geofence: Geofence?
    let weather: Weather?

    @Binding var path: NavigationPath

    @State private var selectedEmotion: Emotion? = nil

    var body: some View {
        VStack(spacing: 24) {

            // ------- Title -------
            Text("Emotion Lock")
                .font(BrandStyle.title)

            // ------- Explanation -------
            Text("Choose an emotion that must match to unlock your note.")
                .font(BrandStyle.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // ------- Emotion List -------
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Emotion.allCases, id: \.self) { emo in

                        EmotionRow(emotion: emo, isSelected: selectedEmotion == emo)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedEmotion == emo ? BrandStyle.accent : .white)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEmotion = emo
                            }

                        if emo != Emotion.allCases.last {
                            Rectangle()
                                .fill(BrandStyle.accent.opacity(0.2))
                                .frame(height: 1)
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(BrandStyle.accent, lineWidth: 1)
            )

            Spacer()

            VStack(spacing: 12) {

                // Skip
                Button {
                    path.append("unlock")
                } label: {
                    Text("Skip Emotion")
                        .font(BrandStyle.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(12)
                }

                // Use
                Button {
                    path.append("unlock")
                } label: {
                    Text("Use Emotion")
                        .font(BrandStyle.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BrandStyle.accent)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

// MARK: - Row
private struct EmotionRow: View {
    let emotion: Emotion
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .white : .black)

            Text(emotion.rawValue.capitalized)
                .font(BrandStyle.body)
                .foregroundColor(isSelected ? .white : .black)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 6)
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

#Preview {
    NavigationStack {
        EmotionLockView(
            title: "Sample Title",
            content: "Sample content for preview",
            geofence: nil,
            weather: nil,
            path: .constant(NavigationPath())
        )
    }
}
