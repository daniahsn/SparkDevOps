import SwiftUI
import CoreLocation

// MARK: - Navigation Enum
enum CreateFlowStep: Hashable {
    case location
    case weather
    case emotion
    case finish
}

struct CreateView: View {
    @EnvironmentObject var location: LocationService
    @EnvironmentObject var weather: WeatherService
    @EnvironmentObject var emotion: EmotionService
    @EnvironmentObject var storage: StorageService

    @State private var path = NavigationPath()
    @State private var title: String = ""
    @State private var content: String = ""

    // Unlock conditions shared across screens
    @State private var geofence: Geofence? = nil
    @State private var weatherCondition: Weather? = nil
    @State private var emotionCondition: Emotion? = nil

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spark")
                        .font(BrandStyle.title)
                        .foregroundColor(BrandStyle.accent)
                    Text("Create Memory")
                        .font(BrandStyle.sectionTitle)
                        .foregroundColor(BrandStyle.textPrimary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

                // --- Title Field ---
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(BrandStyle.caption)
                        .foregroundColor(BrandStyle.textSecondary)

                    TextField("New Memory Title", text: $title)
                        .padding(12)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(BrandStyle.accent, lineWidth: 1.5)
                        )
                }
                .padding(.horizontal)

                // --- Content Field ---
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Memory")
                        .font(BrandStyle.caption)
                        .foregroundColor(BrandStyle.textSecondary)

                    TextEditor(text: $content)
                        .padding(12)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(BrandStyle.accent, lineWidth: 1.5)
                        )
                        .frame(maxHeight: .infinity)
                }
                .padding(.horizontal)

                // --- Next Button ---
                Button {
                    path.append(CreateFlowStep.location)
                } label: {
                    Text("Next")
                        .font(BrandStyle.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BrandStyle.accent)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationDestination(for: CreateFlowStep.self) { step in
                switch step {

                case .location:
                    LocationLockView(
                        geofence: $geofence,
                        path: $path
                    )

                case .weather:
                    WeatherLockView(
                        geofence: $geofence,
                        weather: $weatherCondition,
                        path: $path
                    )

                case .emotion:
                    EmotionLockView(
                        title: title,
                        content: content,
                        geofence: $geofence,
                        weather: $weatherCondition,
                        emotion: $emotionCondition,
                        path: $path
                    )

                case .finish:
                    FinishedView(path: $path)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetCreateFlow)) { _ in
            resetFlow()
        }
    }

    private func resetFlow() {
        title = ""
        content = ""
        geofence = nil
        weatherCondition = nil
        emotionCondition = nil
        path = NavigationPath()
    }
}

#Preview {
    CreateView()
        .environmentObject(LocationService())
        .environmentObject(WeatherService())
        .environmentObject(EmotionService.shared)
        .environmentObject(StorageService.shared)
}
