import SwiftUI
import CoreLocation

struct CreateView: View {
    @EnvironmentObject var location: LocationService
    @EnvironmentObject var weather: WeatherService
    @EnvironmentObject var emotion: EmotionService
    @EnvironmentObject var storage: StorageService
    
    @State private var path = NavigationPath()
    @State private var title: String = ""
    @State private var content: String = ""

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {

                // --- Title Field ---
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(BrandStyle.caption)
                        .foregroundColor(BrandStyle.textSecondary)

                    TextField("New Entry Title", text: $title)
                        .padding(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(BrandStyle.accent, lineWidth: 1)
                        )
                }

                // --- Content Field ---
                VStack(alignment: .leading, spacing: 4) {
                    Text("Content")
                        .font(BrandStyle.caption)
                        .foregroundColor(BrandStyle.textSecondary)

                    TextEditor(text: $content)
                        .padding(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(BrandStyle.accent, lineWidth: 1)
                        )
                        .frame(maxHeight: .infinity)
                }

                // --- Next Button ---
                Button {
                    path.append("location")
                } label: {
                    Text("Next")
                        .font(BrandStyle.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BrandStyle.accent)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Create Entry")
            .navigationDestination(for: String.self) { screen in
                switch screen {
                case "location":
                    LocationLockView(
                        title: title,
                        content: content,
                        path: $path
                    )

                case "weather":
                    WeatherLockView(
                        title: title,
                        content: content,
                        geofence: nil,
                        path: $path
                    )

                case "emotion":
                    EmotionLockView(
                        title: title,
                        content: content,
                        geofence: nil,
                        weather: nil,
                        path: $path
                    )

                case "unlock":
                    EarliestUnlockView(
                        title: title,
                        content: content,
                        geofence: nil,
                        weather: nil,
                        emotion: nil,
                        path: $path
                    )

                case "finish":
                    FinishedView(path: $path)

                default:
                    EmptyView()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetCreateFlow)) { _ in
            title = ""
            content = ""
            path = NavigationPath()     // ← Return completely to beginning
        }
    }
}

#Preview {
    CreateView()
        .environmentObject(LocationService())
        .environmentObject(WeatherService())
        .environmentObject(EmotionService.shared)
        .environmentObject(StorageService.shared)
}
