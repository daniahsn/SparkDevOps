import SwiftUI

struct WeatherLockView: View {
    @EnvironmentObject var weatherService: WeatherService

    // Bind back to CreateView state
    @Binding var geofence: Geofence?
    @Binding var weather: Weather?
    @Binding var path: NavigationPath

    @State private var selectedWeather: Weather? = nil

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Spark")
                    .font(BrandStyle.title)
                    .foregroundColor(BrandStyle.accent)
                Text("Weather Trigger")
                    .font(BrandStyle.sectionTitle)
                    .foregroundColor(BrandStyle.textPrimary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            // ------- Explanation -------
            Text("Pick the weather that will bring back this memory when it returns.")
                .font(BrandStyle.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // ------- Weather Matrix -------
            VStack(spacing: 12) {
                let columns = [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ]
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(weatherOptions, id: \.self) { w in
                        WeatherChip(
                            weather: w,
                            isSelected: selectedWeather == w,
                            onTap: { selectedWeather = w }
                        )
                    }
                }
                
                // Clear Selection Button
                Button { 
                    selectedWeather = nil 
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

            // ------- Buttons -------
            VStack(spacing: 12) {

                // Skip weather
                Button {
                    weather = nil
                    path.append(CreateFlowStep.emotion)
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
                    weather = selectedWeather
                    path.append(CreateFlowStep.emotion)
                } label: {
                    Text("Use Weather")
                        .font(BrandStyle.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedWeather != nil ? BrandStyle.accent : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(selectedWeather == nil)
            }
        }
        .padding()
        .onAppear {
            // Sync previously chosen value from Binding
            selectedWeather = weather
        }
    }

    // MARK: - Weather Options
    private var weatherOptions: [Weather] {
        [
            .clear, .partlyCloudy, .cloudy, .foggy,
            .drizzle, .rain, .snow, .hail, .thunderstorm
        ]
    }
}


// MARK: - Weather Chip

private struct WeatherChip: View {
    let weather: Weather
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                WeatherIcon(weather: weather)
                    .font(.system(size: 20, weight: .medium))
                Text(weather.displayName)
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
        case .hail: return "snowflake"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

#Preview {
    NavigationStack {
        WeatherLockView(
            geofence: .constant(nil),
            weather: .constant(.rain),
            path: .constant(NavigationPath())
        )
        .environmentObject(WeatherService())
    }
}
