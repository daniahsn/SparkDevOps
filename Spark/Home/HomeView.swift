//
//  HomeView.swift
//  Spark
//
//  Created by Julius  Jung on 20.11.2025.
//



import SwiftUI
import CoreLocation
import Combine

struct HomeView: View {
    @EnvironmentObject var location: LocationService
    @EnvironmentObject var weather: WeatherService
    @EnvironmentObject var emotion: EmotionService
    @EnvironmentObject var storage: StorageService
    
    @State private var selectedEmotion: Emotion?
    @State private var currentWeather: Weather?
    @State private var placeName: String = "-"
    @State private var selectedEntry: SparkEntry? = nil
    
    private var recentUnlocked: [SparkEntry] {
        storage.entries
            .filter { $0.unlockedAt != nil }
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
    }
    
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spark")
                        .font(BrandStyle.title)
                        .foregroundColor(BrandStyle.accent)
                    Text("Welcome Back")
                        .font(BrandStyle.sectionTitle)
                        .foregroundColor(BrandStyle.textPrimary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Mood Picker Section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Mood Picker")
                    EmotionPicker(
                        selected: selectedEmotion,
                        onSelect: { setEmotion($0) }
                    )
                }
                .padding(.horizontal)
                
                // Status Section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Status")
                    VStack(spacing: 12) {
                        StatusCard(
                            title: "Weather",
                            subtitle: currentWeather?.displayName ?? "-",
                            symbol: WeatherSymbol.symbol(for: currentWeather ?? .unknown)
                        )
                        StatusCard(
                            title: "Location",
                            subtitle: placeName,
                            symbol: "mappin.and.ellipse"
                        )
                        RefreshCard(isLoading: isRefreshing) { refresh() }
                    }
                }
                .padding(.horizontal)
                
                // Recently Unlocked Section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Recently Unlocked")
                    if recentUnlocked.isEmpty {
                        EmptyStateView()
                    } else {
                        VStack(spacing: 16) {
                            ForEach(recentUnlocked.prefix(5), id: \.id) { entry in
                                NoteCardView(entry: entry) {
                                    // Recent unlocked entries are already unlocked, so safe to navigate
                                    selectedEntry = entry
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    BrandStyle.primary.opacity(0.03),
                    BrandStyle.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .task { await load() }
        .onAppear { location.requestPermission() }
        .onReceive(location.$currentLocation.compactMap { $0 }) { loc in
            Task { 
                await updateForCoordinate(loc.coordinate)
                checkAndUnlockEntries()
            }
        }
        .onReceive(weather.$lastWeather.compactMap { $0 }) { w in
            currentWeather = w
            checkAndUnlockEntries()
        }
        .onReceive(emotion.$currentEmotion) { _ in
            checkAndUnlockEntries()
        }
            .refreshable { await load() }
            .navigationDestination(item: $selectedEntry) { entry in
                NoteDetailView(entry: entry)
            }
        }
    }
    
    private func refresh() {
        Task { await load() }
    }
    
    private func setEmotion(_ newValue: Emotion?) {
        if let value = newValue {
            emotion.setEmotion(value)
        }
        selectedEmotion = newValue
    }
    
    @MainActor
    private func load() async {
        isRefreshing = true
        
        selectedEmotion = emotion.currentEmotion
        
        if let coord = location.currentLocation?.coordinate {
            placeName = await reverseGeocode(coord)
            do {
                currentWeather = try await weather.fetchWeather(
                    lat: coord.latitude, lon: coord.longitude
                )
            } catch {
                currentWeather = weather.lastWeather
            }
        } else {
            placeName = "-"
            currentWeather = weather.lastWeather
        }
        
        storage.load()
        checkAndUnlockEntries()
        isRefreshing = false
    }
    
    private func checkAndUnlockEntries() {
        // Get unlock service from environment
        let unlockService = UnlockService(
            location: location,
            weather: weather,
            emotion: emotion
        )
        
        // Check each locked entry
        for entry in storage.entries where entry.isLocked {
            let shouldUnlock = unlockService.shouldUnlock(entry)
            print("🔓 Checking entry '\(entry.title)': shouldUnlock=\(shouldUnlock)")
            print("  Entry emotion: \(entry.emotion?.rawValue ?? "NIL")")
            print("  Current emotion: \(emotion.currentEmotion?.rawValue ?? "NIL")")
            print("  Entry weather: \(entry.weather?.rawValue ?? "NIL")")
            print("  Current weather: \(weather.lastWeather?.rawValue ?? "NIL")")
            
            if shouldUnlock {
                print("  ✅ Unlocking entry!")
                var unlockedEntry = entry
                unlockedEntry.unlockedAt = Date()
                storage.update(unlockedEntry)
            }
        }
    }
    
    @MainActor
    private func updateForCoordinate(_ coord: CLLocationCoordinate2D) async {
        placeName = await reverseGeocode(coord)
        do {
            currentWeather = try await weather.fetchWeather(lat: coord.latitude, lon: coord.longitude
            )
        } catch {
            currentWeather = weather.lastWeather
        }
    }
    
    @ViewBuilder
    private func SectionHeader(_ text: String) -> some View {
        Text(text)
            .font(BrandStyle.sectionTitle)
            .foregroundColor(BrandStyle.accent)
            .padding(.bottom, 4)
    }
    
    private struct EmotionPicker: View {
        let selected: Emotion?
        let onSelect: (Emotion?) -> Void
        
        private let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
        
        var body: some View {
            VStack(spacing: 12) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Emotion.allCases, id: \.self) { emo in
                        EmotionChip(
                            emotion: emo,
                            isSelected: selected == emo,
                            onTap: { onSelect(emo) }
                        )
                    }
                }
                
                // Clear button
                Button { onSelect(nil) } label: {
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
                            .stroke(BrandStyle.accent, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(BrandStyle.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
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
                .shadow(
                    color: isSelected ? BrandStyle.accent.opacity(0.3) : Color.clear,
                    radius: isSelected ? 4 : 0,
                    x: 0,
                    y: 2
                )
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
    
    private struct StatusCard: View {
        let title: String
        let subtitle: String
        let symbol: String
        
        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(BrandStyle.accent)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [BrandStyle.accent.opacity(0.15), BrandStyle.accent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(BrandStyle.caption)
                        .foregroundColor(BrandStyle.textSecondary)
                    Text(subtitle)
                        .font(BrandStyle.body)
                        .fontWeight(.medium)
                        .foregroundColor(BrandStyle.textPrimary)
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(BrandStyle.accent, lineWidth: 1.5)
            )
        }
    }
    
    private struct RefreshCard: View {
        let isLoading: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(
                            isLoading ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default,
                            value: isLoading
                        )
                    Text("Refresh")
                        .font(BrandStyle.button)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [BrandStyle.accent, BrandStyle.accent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: BrandStyle.accent.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }
    
    private struct EmptyStateView: View {
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "lock.open")
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(BrandStyle.accent.opacity(0.4))
                
                Text("No unlocked memories yet")
                    .font(BrandStyle.sectionTitle)
                    .foregroundColor(BrandStyle.textPrimary)
                
                Text("Preserve your moments and they'll return when the right conditions align")
                    .font(BrandStyle.body)
                    .foregroundColor(BrandStyle.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(BrandStyle.accent, lineWidth: 1.5)
            )
        }
    }
    
    private func reverseGeocode(_ coord: CLLocationCoordinate2D) async -> String {
        do {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(
                CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            )
            return placemarks.first?.locality ?? placemarks.first?.name ?? "-"
        } catch {
            return "-"
        }
    }
    
    
    private enum WeatherSymbol {
        static func symbol(for w: Weather) -> String {
            switch w{
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
}
    
#Preview {
    HomeView()
        .environmentObject(LocationService())
        .environmentObject(WeatherService())
        .environmentObject(EmotionService.shared)
        .environmentObject(StorageService.shared)
}
