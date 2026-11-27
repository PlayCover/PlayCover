//
//  LocationPickerView.swift
//  PlayCover
//

import CoreLocation
import MapKit
import SwiftUI

enum ChinaCoordinateTransform {
    private static let earthRadius = 6378245.0
    private static let eccentricity = 0.00669342162296594323

    static func isInMainlandChina(_ coord: CLLocationCoordinate2D) -> Bool {
        guard coord.longitude >= 72.004 && coord.longitude <= 137.8347 else { return false }
        guard coord.latitude >= 0.8293 && coord.latitude <= 55.8271 else { return false }
        return true
    }

    private static func transformLat(_ deltaLon: Double, _ deltaLat: Double) -> Double {
        var ret = -100.0 + 2.0 * deltaLon + 3.0 * deltaLat + 0.2 * deltaLat * deltaLat
        ret += 0.1 * deltaLon * deltaLat + 0.2 * sqrt(abs(deltaLon))
        ret += (20.0 * sin(6.0 * deltaLon * .pi) + 20.0 * sin(2.0 * deltaLon * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(deltaLat * .pi) + 40.0 * sin(deltaLat / 3.0 * .pi)) * 2.0 / 3.0
        ret += (160.0 * sin(deltaLat / 12.0 * .pi) + 320.0 * sin(deltaLat * .pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    private static func transformLon(_ deltaLon: Double, _ deltaLat: Double) -> Double {
        var ret = 300.0 + deltaLon + 2.0 * deltaLat + 0.1 * deltaLon * deltaLon
        ret += 0.1 * deltaLon * deltaLat + 0.1 * sqrt(abs(deltaLon))
        ret += (20.0 * sin(6.0 * deltaLon * .pi) + 20.0 * sin(2.0 * deltaLon * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(deltaLon * .pi) + 40.0 * sin(deltaLon / 3.0 * .pi)) * 2.0 / 3.0
        ret += (150.0 * sin(deltaLon / 12.0 * .pi) + 300.0 * sin(deltaLon / 30.0 * .pi)) * 2.0 / 3.0
        return ret
    }

    private static func gcjOffset(for coord: CLLocationCoordinate2D) -> (dLat: Double, dLon: Double) {
        var dLat = transformLat(coord.longitude - 105.0, coord.latitude - 35.0)
        var dLon = transformLon(coord.longitude - 105.0, coord.latitude - 35.0)
        let radLat = coord.latitude / 180.0 * .pi
        var magic = sin(radLat)
        magic = 1 - eccentricity * magic * magic
        let sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((earthRadius * (1 - eccentricity)) / (magic * sqrtMagic) * .pi)
        dLon = (dLon * 180.0) / (earthRadius / sqrtMagic * cos(radLat) * .pi)
        return (dLat, dLon)
    }

    static func wgs84ToGcj02(_ wgs: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard isInMainlandChina(wgs) else { return wgs }
        let delta = gcjOffset(for: wgs)
        return CLLocationCoordinate2D(latitude: wgs.latitude + delta.dLat, longitude: wgs.longitude + delta.dLon)
    }

    static func gcj02ToWgs84(_ gcj: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard isInMainlandChina(gcj) else { return gcj }
        var wgs = gcj
        for _ in 0..<8 {
            let shifted = wgs84ToGcj02(wgs)
            let dLat = shifted.latitude - gcj.latitude
            let dLon = shifted.longitude - gcj.longitude
            wgs.latitude -= dLat
            wgs.longitude -= dLon
            if abs(dLat) < 1e-7 && abs(dLon) < 1e-7 {
                break
            }
        }
        return wgs
    }
}

private struct PresetCity: Identifiable {
    let id = UUID()
    let title: String
    let lat: Double
    let lon: Double
}

private let locationPresets: [PresetCity] = [
    PresetCity(title: "北京", lat: 39.90420, lon: 116.40740),
    PresetCity(title: "上海", lat: 31.23040, lon: 121.47370),
    PresetCity(title: "广州", lat: 23.12910, lon: 113.26440),
    PresetCity(title: "深圳", lat: 22.54310, lon: 114.05790),
    PresetCity(title: "香港", lat: 22.31930, lon: 114.16940),
    PresetCity(title: "台北", lat: 25.03300, lon: 121.56540),
    PresetCity(title: "东京", lat: 35.67620, lon: 139.65030),
    PresetCity(title: "纽约", lat: 40.71280, lon: -74.00600),
    PresetCity(title: "旧金山", lat: 37.77490, lon: -122.41940),
    PresetCity(title: "伦敦", lat: 51.50740, lon: -0.12780)
]

private struct InteractiveMapView: NSViewRepresentable {
    let wgsLatitude: Double
    let wgsLongitude: Double
    let applyChinaOffset: Bool
    let recenterVersion: Int
    let onMapPick: (Double, Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsZoomControls = true
        map.showsCompass = true
        map.delegate = context.coordinator

        let click = NSClickGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleClick(_:))
        )
        map.addGestureRecognizer(click)

        let displayCoord = mapCoordinate()
        let annotation = MKPointAnnotation()
        annotation.coordinate = displayCoord
        map.addAnnotation(annotation)
        context.coordinator.annotation = annotation
        map.setRegion(MKCoordinateRegion(center: displayCoord,
                                       span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)),
                      animated: false)
        return map
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        let displayCoord = mapCoordinate()
        if let ann = context.coordinator.annotation {
            if abs(ann.coordinate.latitude - displayCoord.latitude) > 1e-6
                || abs(ann.coordinate.longitude - displayCoord.longitude) > 1e-6 {
                ann.coordinate = displayCoord
            }
        }
        if context.coordinator.lastRecenterVersion != recenterVersion {
            context.coordinator.lastRecenterVersion = recenterVersion
            mapView.setCenter(displayCoord, animated: true)
        }
    }

    private func mapCoordinate() -> CLLocationCoordinate2D {
        let wgs = CLLocationCoordinate2D(latitude: wgsLatitude, longitude: wgsLongitude)
        return applyChinaOffset ? ChinaCoordinateTransform.wgs84ToGcj02(wgs) : wgs
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: InteractiveMapView
        var annotation: MKPointAnnotation?
        var lastRecenterVersion = 0

        init(_ parent: InteractiveMapView) {
            self.parent = parent
        }

        @objc func handleClick(_ recognizer: NSClickGestureRecognizer) {
            guard let map = recognizer.view as? MKMapView else { return }
            let clickPoint = recognizer.location(in: map)
            let tapped = map.convert(clickPoint, toCoordinateFrom: map)
            let wgs = parent.applyChinaOffset ? ChinaCoordinateTransform.gcj02ToWgs84(tapped) : tapped
            DispatchQueue.main.async {
                self.parent.onMapPick(wgs.latitude, wgs.longitude)
            }
        }
    }
}

struct LocationPickerView: View {
    @Binding var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var wgsLat: Double
    @State private var wgsLon: Double
    @State private var locationName: String
    @State private var latText: String
    @State private var lonText: String
    @State private var searchQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var applyChinaOffset = true
    @State private var recenterVersion = 0

    init(settings: Binding<AppSettings>) {
        self._settings = settings
        let data = settings.wrappedValue.settings
        let lat = data.mockLocationLatitude
        let lon = data.mockLocationLongitude
        let name = data.mockLocationName
        _wgsLat = State(initialValue: lat)
        _wgsLon = State(initialValue: lon)
        _locationName = State(initialValue: name)
        _latText = State(initialValue: String(format: "%.5f", lat))
        _lonText = State(initialValue: String(format: "%.5f", lon))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings.location.title")
                .font(.headline)

            HStack {
                TextField("settings.location.searchPlaceholder", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { performSearch() }
                Button("settings.location.searchButton") {
                    performSearch()
                }
                .disabled(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
            }

            if !searchResults.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(searchResults.enumerated()), id: \.offset) { _, item in
                            Button {
                                selectMapItem(item)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.name ?? "")
                                            .fontWeight(.medium)
                                        if let title = item.placemark.title, !title.isEmpty {
                                            Text(title)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 110)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
            }

            InteractiveMapView(
                wgsLatitude: wgsLat,
                wgsLongitude: wgsLon,
                applyChinaOffset: applyChinaOffset,
                recenterVersion: recenterVersion,
                onMapPick: { lat, lon in
                    wgsLat = lat
                    wgsLon = lon
                    latText = String(format: "%.5f", lat)
                    lonText = String(format: "%.5f", lon)
                    locationName = String(format: "%.4f, %.4f", lat, lon)
                }
            )
            .frame(height: 280)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(locationPresets) { preset in
                        Button(preset.title) {
                            wgsLat = preset.lat
                            wgsLon = preset.lon
                            latText = String(format: "%.5f", preset.lat)
                            lonText = String(format: "%.5f", preset.lon)
                            locationName = preset.title
                            recenterVersion += 1
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("settings.location.latitude")
                    TextField("39.90420", text: $latText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .onChange(of: latText) { val in
                            handleCoordinateInput(val)
                        }
                }
                HStack(spacing: 4) {
                    Text("settings.location.longitude")
                    TextField("116.40740", text: $lonText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .onChange(of: lonText) { val in
                            if let parsedLon = Double(val.trimmingCharacters(in: .whitespaces)),
                               parsedLon >= -180 && parsedLon <= 180 {
                                wgsLon = parsedLon
                            }
                        }
                }
                Spacer()
                Text(locationName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Toggle("settings.location.chinaShift", isOn: $applyChinaOffset)
                .help("settings.location.chinaShift.help")

            HStack {
                Spacer()
                Button("settings.location.cancel") {
                    dismiss()
                }
                Button("settings.location.done") {
                    settings.settings.mockLocationLatitude = wgsLat
                    settings.settings.mockLocationLongitude = wgsLon
                    settings.settings.mockLocationName = locationName
                    settings.settings.mockLocationEnabled = true
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 560, height: 560)
    }

    private func handleCoordinateInput(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count == 2,
           let lat = Double(parts[0]),
           let lon = Double(parts[1]),
           lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180 {
            wgsLat = lat
            wgsLon = lon
            latText = String(format: "%.5f", lat)
            lonText = String(format: "%.5f", lon)
            recenterVersion += 1
            return
        }
        if let lat = Double(trimmed), lat >= -90 && lat <= 90 {
            wgsLat = lat
        }
    }

    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = query
        MKLocalSearch(request: req).start { response, _ in
            DispatchQueue.main.async {
                isSearching = false
                let items = response?.mapItems ?? []
                searchResults = items
                if items.count == 1, let first = items.first {
                    selectMapItem(first, clearResults: true)
                } else if let first = items.first {
                    selectMapItem(first, clearResults: false)
                }
            }
        }
    }

    private func selectMapItem(_ item: MKMapItem, clearResults: Bool = true) {
        let coord = item.placemark.coordinate
        let wgs = applyChinaOffset ? ChinaCoordinateTransform.gcj02ToWgs84(coord) : coord
        wgsLat = wgs.latitude
        wgsLon = wgs.longitude
        latText = String(format: "%.5f", wgs.latitude)
        lonText = String(format: "%.5f", wgs.longitude)
        locationName = item.name ?? String(format: "%.4f, %.4f", wgs.latitude, wgs.longitude)
        recenterVersion += 1
        if clearResults {
            searchResults = []
        }
    }
}
