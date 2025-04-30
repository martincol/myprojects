//
//  ContentView.swift
//  TestiOSApp
//
//  Created by Martin Collins on 26/04/2025.
//

import SwiftUI
import MapKit
import CoreLocation
import Foundation
import XMLCoder

struct POI: Equatable {
    let coordinate: CLLocationCoordinate2D
    let title: String
    let description: String
    let category: String
    let imageName: String? // Optional image name
    
    static func == (lhs: POI, rhs: POI) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.category == rhs.category &&
               lhs.imageName == rhs.imageName
    }
}

// Add color mapping for categories
extension POI {
    var color: UIColor {
        switch category.lowercased() {
        case "museum":
            return .systemPurple
        case "park":
            return .systemGreen
        case "historic":
            return .systemBrown
        case "shopping":
            return .systemBlue
        case "restaurant":
            return .systemRed
        case "entertainment":
            return .systemOrange
        case "transport":
            return .systemGray
        case "education":
            return .systemIndigo
        case "sports":
            return .systemTeal
        default:
            return .systemPink
        }
    }
}

struct GPXPoint: Codable {
    let lat: String
    let lon: String
    let ele: String?
    
    enum CodingKeys: String, CodingKey {
        case lat
        case lon
        case ele
    }
}

struct GPXTrack: Codable {
    let name: String?
    let points: [GPXPoint]
    
    enum CodingKeys: String, CodingKey {
        case name
        case points = "trkpt"
    }
}

struct GPX: Codable {
    let track: GPXTrack
    
    enum CodingKeys: String, CodingKey {
        case track = "trk"
    }
}

struct Route: Codable {
    let name: String
    let description: String
    let gpxFileName: String
    let distance: Double
    let duration: String
}

struct ContentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.9097, longitude: -1.4044), // Southampton coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var mapType: MKMapType = .standard
    @State private var selectedPOI: POI? = nil
    @State private var showPOIPopup = false
    @State private var showPOIList = false
    @State private var selectedCategory: String = "All"
    @State private var showCategoryPicker = false
    @State private var showRoutePicker = false
    @State private var selectedRoute: Route? = nil
    @State private var htmlAttributedString: AttributedString? = nil

    let pois = loadPOIsFromCSV()
    let routes = loadRoutesFromCSV()
    
    var categories: [String] {
        let allCategories = Set(pois.map { $0.category })
        return ["All"] + allCategories.sorted()
    }
    
    var filteredPOIs: [POI] {
        if selectedCategory == "All" {
            return pois
        } else {
            return pois.filter { $0.category == selectedCategory }
        }
    }

    var body: some View {
        ZStack {
            MapView(region: $region, mapType: $mapType, selectedRoute: $selectedRoute, pois: filteredPOIs, onPOITap: { poi in
                selectedPOI = poi
                showPOIPopup = true
            })
            .edgesIgnoringSafeArea(.horizontal)
            .frame(maxHeight: .infinity)

            VStack {
                HStack {
                    Button(action: {
                        showCategoryPicker.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    Button(action: {
                        showPOIList.toggle()
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding()
                }
                Spacer()
                
                HStack {
                    Button(action: {
                        showRoutePicker.toggle()
                    }) {
                        Image(systemName: "figure.walk")
                            .font(.title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(.bottom, 8)
            }
        }
        .overlay(
            Group {
                if showCategoryPicker {
                    VStack {
                        Text("Filter by Category")
                            .font(.title2)
                            .padding()
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                        
                        HStack {
                            Button("Cancel") {
                                showCategoryPicker = false
                            }
                            .padding()
                            
                            Button("Apply") {
                                showCategoryPicker = false
                            }
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding()
                    .transition(.move(edge: .bottom))
                }
                
                if showRoutePicker {
                    VStack {
                        Text("Select Walking Route")
                            .font(.title)
                            .padding()
                        
                        List(routes, id: \.name) { route in
                            Button(action: {
                                selectedRoute = route
                                showRoutePicker = false
                            }) {
                                VStack(alignment: .leading) {
                                    Text(route.name)
                                        .font(.headline)
                                    Text(route.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    HStack {
                                        Text("\(String(format: "%.1f", route.distance)) km")
                                        Text("•")
                                        Text(route.duration)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        
                        Button(action: {
                            print("No Route selected - removing current route")
                            selectedRoute = nil
                            showRoutePicker = false
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("No Route")
                            }
                            .foregroundColor(.red)
                        }
                        .padding()
                        
                        Button("Cancel") {
                            showRoutePicker = false
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding()
                    .transition(.move(edge: .trailing))
                }
                
                if showPOIList {
                    VStack {
                        Text("Points of Interest")
                            .font(.title)
                            .padding()
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                        
                        List(filteredPOIs, id: \.title) { poi in
                            Button(action: {
                                // Center map on selected POI
                                withAnimation {
                                    region = MKCoordinateRegion(
                                        center: poi.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                    showPOIList = false
                                }
                            }) {
                                VStack(alignment: .leading) {
                                    Text(poi.title)
                                        .font(.headline)
                                    Text(poi.category)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        
                        Button("Close") {
                            showPOIList = false
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding()
                    .transition(.move(edge: .trailing))
                }
                
                if showPOIPopup, let poi = selectedPOI {
                    VStack {
                        Spacer()
                        ScrollView {
                            VStack(spacing: 16) {
                                Text(poi.title)
                                    .font(.title)
                                    .bold()
                                
                                if let imageName = poi.imageName,
                                   let image = UIImage(named: imageName) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .cornerRadius(10)
                                }
                                
                                HTMLTextView(html: poi.description)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("Category: \(poi.category)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Button("Close") {
                                    showPOIPopup = false
                                    selectedPOI = nil
                                }
                                .padding(.top)
                            }
                            .padding()
                            .frame(maxWidth: UIScreen.main.bounds.width - 40)
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(radius: 10)
                            .padding()
                        }
                        Spacer()
                    }
                    .background(Color.black.opacity(0.4).ignoresSafeArea())
                    .transition(.move(edge: .bottom))
                }
            }
        )
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: MKMapType
    @Binding var selectedRoute: Route?
    var pois: [POI]
    var onPOITap: (POI) -> Void
    
    // Add reference to the map view
    @State private var mapView: MKMapView?
    @State private var routeOverlay: MKPolyline?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        self.mapView = mapView // Store reference
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        
        // Set up offline tile overlay first
        let overlay = OfflineTileOverlay()
        overlay.canReplaceMapContent = true
        mapView.addOverlay(overlay, level: .aboveLabels)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        self.mapView = mapView // Update reference
        mapView.setRegion(region, animated: true)
        mapView.mapType = mapType

        // Remove old POI annotations (but not user location)
        let nonUserAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(nonUserAnnotations)

        // Add POI annotations
        for poi in pois {
            let annotation = MKPointAnnotation()
            annotation.title = poi.title
            annotation.coordinate = poi.coordinate
            mapView.addAnnotation(annotation)
        }
        
        // Update route overlay if route selection changed
        if let route = selectedRoute {
            print("Loading route: \(route.name)")
            loadAndDisplayRoute(route, on: mapView)
        } else {
            print("Removing route overlay - selectedRoute: nil")
            // Remove all overlays except the tile overlay
            let overlays = mapView.overlays
            for overlay in overlays {
                if !(overlay is MKTileOverlay) {
                    print("Removing overlay: \(overlay)")
                    mapView.removeOverlay(overlay)
                }
            }
            routeOverlay = nil
        }
    }
    
    private func loadAndDisplayRoute(_ route: Route, on mapView: MKMapView) {
        print("Starting to load route: \(route.name)")
        
        // Remove all overlays except the tile overlay
        let overlays = mapView.overlays
        for overlay in overlays {
            if !(overlay is MKTileOverlay) {
                print("Removing previous overlay: \(overlay)")
                mapView.removeOverlay(overlay)
            }
        }
        routeOverlay = nil
        
        // Remove any existing route markers
        let routeMarkers = mapView.annotations.filter { $0 is MKPointAnnotation && $0.title == "Start" }
        mapView.removeAnnotations(routeMarkers)
        
        if let gpxPath = Bundle.main.path(forResource: route.gpxFileName, ofType: "gpx") {
            print("Found GPX file at: \(gpxPath)")
            if let gpxData = try? Data(contentsOf: URL(fileURLWithPath: gpxPath)) {
                do {
                    let decoder = XMLDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    let gpx = try decoder.decode(GPX.self, from: gpxData)
                    print("Successfully decoded GPX with \(gpx.track.points.count) points")
                    
                    let coordinates = gpx.track.points.compactMap { point -> CLLocationCoordinate2D? in
                        guard let lat = Double(point.lat),
                              let lon = Double(point.lon) else {
                            print("Failed to convert coordinates: lat=\(point.lat), lon=\(point.lon)")
                            return nil
                        }
                        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                    
                    if coordinates.isEmpty {
                        print("No valid coordinates found after conversion")
                    } else {
                        print("Successfully converted \(coordinates.count) coordinates")
                        
                        // Add start marker at first coordinate
                        if let firstCoordinate = coordinates.first {
                            let startMarker = MKPointAnnotation()
                            startMarker.title = "Start"
                            startMarker.coordinate = firstCoordinate
                            mapView.addAnnotation(startMarker)
                            print("Added start marker at first coordinate")
                        }
                        
                        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                        routeOverlay = polyline
                        mapView.addOverlay(polyline, level: .aboveLabels)
                        print("Added polyline overlay with \(coordinates.count) points")
                        
                        // Zoom to show the entire route
                        var region = MKCoordinateRegion()
                        var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
                        var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
                        
                        for coordinate in coordinates {
                            topLeftCoord.longitude = min(topLeftCoord.longitude, coordinate.longitude)
                            topLeftCoord.latitude = max(topLeftCoord.latitude, coordinate.latitude)
                            bottomRightCoord.longitude = max(bottomRightCoord.longitude, coordinate.longitude)
                            bottomRightCoord.latitude = min(bottomRightCoord.latitude, coordinate.latitude)
                        }
                        
                        let center = CLLocationCoordinate2D(
                            latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5,
                            longitude: topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5
                        )
                        
                        let span = MKCoordinateSpan(
                            latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.3,
                            longitudeDelta: abs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.3
                        )
                        
                        region = MKCoordinateRegion(center: center, span: span)
                        mapView.setRegion(region, animated: true)
                    }
                } catch {
                    print("Error decoding GPX: \(error)")
                }
            } else {
                print("Failed to load GPX data")
            }
        } else {
            print("Could not find GPX file in bundle")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, pois: pois, onPOITap: onPOITap)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView
        let locationManager = CLLocationManager()
        let pois: [POI]
        let onPOITap: (POI) -> Void
        
        init(_ parent: MapView, pois: [POI], onPOITap: @escaping (POI) -> Void) {
            self.parent = parent
            self.pois = pois
            self.onPOITap = onPOITap
            super.init()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            // Update map view with new heading
            if let mapView = parent.mapView {
                mapView.userTrackingMode = .followWithHeading
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tileOverlay)
            }
            
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 3
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "Pin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize the marker for the start point
            if annotation.title == "Start" {
                annotationView?.markerTintColor = .systemGreen
                annotationView?.glyphText = "S"
                annotationView?.glyphTintColor = .white
            } else if let title = annotation.title ?? "",
                      let poi = pois.first(where: { $0.title == title }) {
                annotationView?.markerTintColor = poi.color
                annotationView?.glyphTintColor = .white
            }
            
            return annotationView
        }
        
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            print("Map finished loading - tiles are cached for offline use")
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation else { return }
            // Find the POI that matches this annotation
            if let poi = pois.first(where: { $0.title == annotation.title && $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) {
                onPOITap(poi)
            }
        }
    }
}

class OfflineTileOverlay: MKTileOverlay {
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        // First try to load from disk
        if let tileData = loadTileDataFromDisk(x: path.x, y: path.y, z: path.z) {
            result(tileData, nil)
            return
        }
    }
    
    private func loadTileDataFromDisk(x: Int, y: Int, z: Int) -> Data? {
        // Try to load from app bundle (blue folder reference)

        if let bundlePath = Bundle.main.path(forResource: "\(z)-\(x)-\(y)", ofType: "png") {
            print("Loading tile from bundle: z:\(z) x:\(x) y:\(y)")
            return try? Data(contentsOf: URL(fileURLWithPath: bundlePath))
        }
        
        return nil
    }
}
    

func downloadVisibleTilesForRegion(_ region: MKCoordinateRegion) {
    // Southampton region
    let minZoom = 12
    let maxZoom = 16
    
    // Create directory structure
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return
    }
    
    let tileDirectory = documentsDirectory.appendingPathComponent("map_tiles")
    try? FileManager.default.createDirectory(at: tileDirectory, withIntermediateDirectories: true)
    
    // Download each tile in the region at each zoom level
    for zoom in minZoom...maxZoom {
        let tiles = getTilesForRegion(region, zoom: zoom)
        print("Downloading \(tiles.count) tiles for zoom level \(zoom)")
        for tile in tiles {
            downloadTile(x: tile.x, y: tile.y, zoom: zoom)
        }
    }
}

func getTilesForRegion(_ region: MKCoordinateRegion, zoom: Int) -> [(x: Int, y: Int)] {
    var tiles = [(x: Int, y: Int)]()
    
    // Convert region coordinates to tile coordinates
    let nwLat = region.center.latitude + region.span.latitudeDelta / 2
    let nwLon = region.center.longitude - region.span.longitudeDelta / 2
    let seLat = region.center.latitude - region.span.latitudeDelta / 2
    let seLon = region.center.longitude + region.span.longitudeDelta / 2
    
    // Get tile coordinates for the corners
    let nwTile = latLonToTile(lat: nwLat, lon: nwLon, zoom: zoom)
    let seTile = latLonToTile(lat: seLat, lon: seLon, zoom: zoom)
    
    // Loop through all the tiles in the region
    for x in nwTile.x...seTile.x {
        for y in nwTile.y...seTile.y {
            tiles.append((x: x, y: y))
        }
    }
    
    return tiles
}

func latLonToTile(lat: Double, lon: Double, zoom: Int) -> (x: Int, y: Int) {
    let n = pow(2.0, Double(zoom))
    let radLat = lat * .pi / 180.0
    
    let x = Int((lon + 180.0) / 360.0 * n)
    let y = Int((1.0 - log(tan(radLat) + 1.0 / cos(radLat)) / .pi) / 2.0 * n)
    
    return (x: x, y: y)
}

func downloadTile(x: Int, y: Int, zoom: Int) {
    print("\(zoom),\(x),\(y)")
}

// Helper to split a CSV line, handling quoted fields
func splitCSVLine(_ line: String) -> [String] {
    var results: [String] = []
    var value = ""
    var insideQuotes = false
    var iterator = line.makeIterator()
    while let char = iterator.next() {
        if char == "\"" {
            insideQuotes.toggle()
        } else if char == "," && !insideQuotes {
            results.append(value)
            value = ""
        } else {
            value.append(char)
        }
    }
    results.append(value)
    return results.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") }
}

func loadPOIsFromCSV() -> [POI] {
    guard let path = Bundle.main.path(forResource: "pois", ofType: "csv"),
          let content = try? String(contentsOfFile: path) else {
        print("CSV file not found")
        return []
    }
    var pois: [POI] = []
    let lines = content.components(separatedBy: .newlines)
    for line in lines {
        let fields = splitCSVLine(line)
        if fields.count >= 5,
           let lat = Double(fields[0]),
           let lon = Double(fields[1]) {
            let title = fields[2]
            let description = fields[3]
            let category = fields[4]
            let imageName = fields.count > 5 ? fields[5] : nil // Optional 6th field for image name
            let poi = POI(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                title: title,
                description: description,
                category: category,
                imageName: imageName
            )
            pois.append(poi)
        }
    }
    return pois
}

func loadRoutesFromCSV() -> [Route] {
    guard let path = Bundle.main.path(forResource: "routes", ofType: "csv"),
          let content = try? String(contentsOfFile: path) else {
        print("Routes CSV file not found")
        return []
    }
    var routes: [Route] = []
    let lines = content.components(separatedBy: .newlines)
    for line in lines {
        let fields = splitCSVLine(line)
        if fields.count >= 5,
           let distance = Double(fields[3]) {
            let name = fields[0]
            let description = fields[1]
            let gpxFileName = fields[2]
            let duration = fields[4]
            let route = Route(
                name: name,
                description: description,
                gpxFileName: gpxFileName,
                distance: distance,
                duration: duration
            )
            routes.append(route)
        }
    }
    return routes
}

struct HTMLTextView: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if let data = html.data(using: .utf8),
           let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
           ) {
            uiView.attributedText = attributedString

            // Force layout update
            uiView.layoutManager.ensureLayout(for: uiView.textContainer)
            let size = uiView.sizeThatFits(CGSize(width: uiView.frame.width, height: .greatestFiniteMagnitude))
            uiView.frame.size = size
        } else {
            uiView.text = html
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? .infinity
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return size
    }
}

#Preview {
    ContentView()
}

