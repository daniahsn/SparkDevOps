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

    // Bind back to CreateView's geofence
    @Binding var geofence: Geofence?
    @Binding var path: NavigationPath

    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion()
    @State private var showFullScreenMap = false

    // NEW: radius in meters
    @State private var radiusInMeters: String = "100"

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Spark")
                    .font(BrandStyle.title)
                    .foregroundColor(BrandStyle.accent)
                Text("Location Trigger")
                    .font(BrandStyle.sectionTitle)
                    .foregroundColor(BrandStyle.textPrimary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Choose a place where this memory will be retrieved when you return.")
                .font(BrandStyle.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // MARK: - Map Preview
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
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(BrandStyle.accent, lineWidth: 1.5)
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

            // MARK: - Radius Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Radius (meters)")
                    .font(BrandStyle.caption)
                    .foregroundColor(BrandStyle.textSecondary)

                TextField("100", text: $radiusInMeters)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BrandStyle.accent, lineWidth: 1.5)
                    )
            }

            Spacer()

            // MARK: - Buttons
            VStack(spacing: 12) {

                // Skip → go to weather
                Button {
                    geofence = nil
                    path.append(CreateFlowStep.weather)
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
                    path.append(CreateFlowStep.weather)
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
        .onAppear { loadExistingSelectionOrInitialize() }
        .fullScreenCover(isPresented: $showFullScreenMap) {
            FullScreenLocationPicker(selectedCoordinate: $selectedCoordinate)
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

    // MARK: - On Appear: Load existing selection
    private func loadExistingSelectionOrInitialize() {
        if let gf = geofence {
            // Load previously selected geofence
            let coord = CLLocationCoordinate2D(latitude: gf.latitude, longitude: gf.longitude)
            selectedCoordinate = coord
            radiusInMeters = "\(Int(gf.radius))"
            updateRegion()
        } else if let current = location.currentLocation {
            // Default to user's current location
            selectedCoordinate = current.coordinate
            updateRegion()
        }
    }

    // MARK: - Confirm Location
    private func confirmLocation() {
        guard let coord = selectedCoordinate else {
            geofence = nil
            return
        }

        let radius = Double(radiusInMeters) ?? 100

        geofence = Geofence(
            latitude: coord.latitude,
            longitude: coord.longitude,
            radius: radius
        )
    }
}


// =====================================================================
// MARK: - Full Screen Picker
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
                    .cornerRadius(12)
                    .onChange(of: searchQuery) { text in
                        completer.queryFragment = text
                    }

                Button("Cancel") { dismiss() }
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
                    .cornerRadius(12)
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
