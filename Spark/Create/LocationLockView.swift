import SwiftUI
import MapKit
import CoreLocation
import Combine

// A wrapper to show a map pin
struct MapPinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct LocationLockView: View {
    @EnvironmentObject var location: LocationService

    let title: String
    let content: String

    @Binding var path: NavigationPath

    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion()
    @State private var showFullScreenMap = false

    @State private var passedGeofence: Geofence? = nil

    var body: some View {
        VStack(spacing: 24) {

            // ------- Title -------
            Text("Location Lock")
                .font(BrandStyle.title)

            Text("Expand map to choose a location, which needs to be visited to unlock your note.")
                .font(BrandStyle.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // ------- Map Preview -------
            ZStack {
                Map(
                    coordinateRegion: $region,
                    annotationItems: mapPins
                ) { pin in
                    MapMarker(coordinate: pin.coordinate)
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onReceive(Just(selectedCoordinate)) { _ in updateRegion() }
                .onTapGesture { showFullScreenMap = true }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(BrandStyle.accent, lineWidth: 1)
                )

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showFullScreenMap = true
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(12)
                    }
                }
            }

            Spacer()

            // ------- Buttons -------
            VStack(spacing: 12) {

                // Skip → go to weather
                Button {
                    passedGeofence = nil
                    path.append("weather")
                } label: {
                    Text("Skip Location")
                        .font(BrandStyle.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(12)
                }

                // Use Location
                Button {
                    confirmLocation()
                    path.append("weather")
                } label: {
                    Text("Use Location")
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
        .onAppear { initializePin() }
        .fullScreenCover(isPresented: $showFullScreenMap) {
            FullScreenLocationPicker(selectedCoordinate: $selectedCoordinate)
        }
        .navigationDestination(for: String.self) { screen in
            switch screen {
            case "weather":
                WeatherLockView(
                    title: title,
                    content: content,
                    geofence: passedGeofence,
                    path: $path
                )
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Map Pins
    private var mapPins: [MapPinItem] {
        if let c = selectedCoordinate {
            return [MapPinItem(coordinate: c)]
        }
        return []
    }

    // MARK: - Region Centering
    private func updateRegion() {
        guard let coord = selectedCoordinate else { return }
        region = MKCoordinateRegion(
            center: coord,
            span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    private func initializePin() {
        if let current = location.currentLocation {
            selectedCoordinate = current.coordinate
            updateRegion()
        }
    }

    private func confirmLocation() {
        if let coord = selectedCoordinate {
            passedGeofence = Geofence(
                latitude: coord.latitude,
                longitude: coord.longitude,
                radius: 150
            )
        } else {
            passedGeofence = nil
        }
    }
}


// =====================================================================
// MARK: - Full Screen Picker with Apple Maps Search
// =====================================================================

struct FullScreenLocationPicker: View {
    @Environment(\.dismiss) var dismiss

    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    @State private var region = MKCoordinateRegion()
    @State private var searchQuery = ""

    @State private var completer = MKLocalSearchCompleter()
    @State private var completions: [MKLocalSearchCompletion] = []
    @State private var completerDelegate: SearchCompleterDelegate? = nil

    var body: some View {
        VStack(spacing: 0) {

            // ------- Search Bar -------
            HStack {
                TextField("Search for places", text: $searchQuery)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                    .onChange(of: searchQuery) { text in
                        completer.queryFragment = text
                    }

                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(BrandStyle.accent)
            }
            .padding(.horizontal)
            .padding(.top, 50)

            Spacer(minLength: 8)

            // ------- Search Results -------
            if !completions.isEmpty {
                List(completions, id: \.self) { item in
                    Button {
                        searchCompletionSelected(item)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.title)
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            } else if !searchQuery.isEmpty {
                Text("No results found")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }

            // ------- Map -------
            ZStack {
                Map(coordinateRegion: $region, showsUserLocation: true)
                    .ignoresSafeArea()

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.red)
                    .offset(y: -20)

                VStack {
                    Spacer()
                    Button("Set Location") {
                        selectedCoordinate = region.center
                        dismiss()
                    }
                    .font(BrandStyle.button)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(BrandStyle.accent)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding()
                }
            }
        }
        .onAppear {
            configureInitialRegion()
            setupCompleter()
        }
    }

    // MARK: - Setup Search Completer
    private func setupCompleter() {
        completer.resultTypes = .address

        let delegate = SearchCompleterDelegate { results in
            self.completions = results
        }
        self.completerDelegate = delegate
        completer.delegate = delegate
    }

    // MARK: - Search selection
    private func searchCompletionSelected(_ completion: MKLocalSearchCompletion) {
        let req = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: req).start { res, _ in
            guard let item = res?.mapItems.first,
                  let coord = item.placemark.location?.coordinate else { return }

            selectedCoordinate = coord
            centerOn(coord)
            completions = []
            searchQuery = ""
        }
    }

    private func centerOn(_ coord: CLLocationCoordinate2D) {
        region.center = coord
    }

    private func configureInitialRegion() {
        if let coord = selectedCoordinate {
            region = MKCoordinateRegion(
                center: coord,
                span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}


// ---------- MARK: Delegate ----------
final class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    let onUpdate: ([MKLocalSearchCompletion]) -> Void

    init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onUpdate = onUpdate
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onUpdate([])
    }
}

#Preview {
    NavigationStack {
        LocationLockView(
            title: "Sample Title",
            content: "Sample content for preview",
            path: .constant(NavigationPath())
        )
        .environmentObject(LocationService())
    }
}
