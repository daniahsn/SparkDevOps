import SwiftUI

struct WeatherLockView: View {
    @EnvironmentObject var weatherService: WeatherService

    let title: String
    let content: String
    let geofence: Geofence?
    @Binding var path: NavigationPath

    @State private var selectedWeather: Weather? = nil

    var body: some View {
        VStack(spacing: 24) {

            // ------- Title -------
            Text("Weather Lock")
                .font(BrandStyle.title)

            // ------- Explanatory -------
            Text("Choose a weather condition that must match to unlock your note.")
                .font(BrandStyle.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // ------- Weather List -------
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(weatherOptions, id: \.self) { w in

                        WeatherRow(weather: w, isSelected: selectedWeather == w)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedWeather == w ? BrandStyle.accent : .white)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedWeather = w
                            }

                        if w != weatherOptions.last {
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

            // ------- Buttons -------
            VStack(spacing: 12) {

                // Skip weather
                Button {
                    path.append("emotion")
                } label: {
                    Text("Skip Weather")
                        .font(BrandStyle.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(12)
                }

                // Use weather
                Button {
                    path.append("emotion")
                } label: {
                    Text("Use Weather")
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
        .navigationDestination(for: String.self) { screen in
            switch screen {
            case "emotion":
                EmotionLockView(
                    title: title,
                    content: content,
                    geofence: geofence,
                    weather: selectedWeather,
                    path: $path
                )
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Weather Options
    private var weatherOptions: [Weather] {
        [
            .clear, .partlyCloudy, .cloudy, .foggy,
            .drizzle, .rain, .snow, .snowGrains, .thunderstorm
        ]
    }
}


// MARK: - Weather Row View

private struct WeatherRow: View {
    let weather: Weather
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {

            WeatherIcon(weather: weather)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .white : .black)

            Text(weather.rawValue.capitalized)
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
}


// MARK: - Weather Icon

struct WeatherIcon: View {
    let weather: Weather

    var body: some View {
        Image(systemName: symbol)
    }

    private var symbol: String {
        switch weather {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .freezingRain: return "cloud.sleet.fill"
        case .snow: return "cloud.snow.fill"
        case .snowGrains: return "snowflake"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

#Preview {
    NavigationStack {
        WeatherLockView(
            title: "Sample Title",
            content: "Sample content for preview",
            geofence: nil,
            path: .constant(NavigationPath())
        )
        .environmentObject(WeatherService())
    }
}
