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
import WebKit

struct POI: Equatable {
    let coordinate: CLLocationCoordinate2D
    let title: String
    let description: String
    let categories: [String]
    let imageName: String? // Optional image name
    
    static func == (lhs: POI, rhs: POI) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.categories == rhs.categories &&
               lhs.imageName == rhs.imageName
    }
}

// Add color mapping for categories
extension POI {
    var color: Color {
        // Use the first category for color
        guard let firstCategory = categories.first?.lowercased() else {
            return .pink
        }
        
        switch firstCategory {
        case "museum":
            return .purple
        case "park":
            return .green
        case "historic":
            return .brown
        case "shopping":
            return .blue
        case "restaurant":
            return .red
        case "entertainment":
            return .orange
        case "transport":
            return .gray
        case "education":
            return .indigo
        case "sports":
            return .teal
        default:
            return .pink
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

struct POIPopupView: View {
    let poi: POI
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(poi.title)
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                    
                    if let imageName = poi.imageName, !imageName.isEmpty {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(10)
                    }
                    
                    Text(poi.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Categories: \(poi.categories.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            Button("Close") {
                onClose()
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}

struct POIDetailView: View {
    let poi: POI
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(poi.title)
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                    
                    // Image if available
                    if let imageName = poi.imageName, !imageName.isEmpty {
                        if let image = UIImage(named: imageName) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        } else {
                            Text("Image not found: \(imageName)")
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    
                    // Description
                    if poi.description.contains("<") && poi.description.contains(">") {
                        HTMLTextView(html: poi.description)
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                    } else {
                        Text(poi.description)
                            .font(.body)
                            .padding(.horizontal)
                    }
                    
                    // Categories
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Categories")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(poi.categories, id: \.self) { category in
                                Text(category)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Helper view for horizontal flow layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for size in sizes {
            if lineWidth + size.width > (proposal.width ?? .infinity) {
                width = max(width, lineWidth - spacing)
                height += lineHeight + spacing
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        
        width = max(width, lineWidth - spacing)
        height += lineHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        
        for (index, size) in sizes.enumerated() {
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            
            subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// Add this class at the top of the file, before the ContentView struct
class TileDownloadManager: ObservableObject {
    @Published var isDownloading = false
    
    static func downloadTiles(for region: MKCoordinateRegion, completion: @escaping () -> Void) {
        // Create a local copy of the region to avoid capturing self
        let regionCopy = region
        
        // Perform download on background queue
        DispatchQueue.global(qos: .userInitiated).async {
            downloadVisibleTilesForRegion(regionCopy)
            
            // Call completion on main queue
            DispatchQueue.main.async {
                completion()
            }
        }
    }
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
    @State private var selectedCategories: Set<String> = Set() // Track selected categories
    @State private var showCategoryPicker = false
    @State private var showRoutePicker = false
    @State private var selectedRoute: Route? = nil
    @State private var htmlAttributedString: AttributedString? = nil
    @State private var selectedCategory: String = "All"
    @StateObject private var tileDownloadManager = TileDownloadManager()

    let pois = loadPOIsFromCSV()
    let routes = loadRoutesFromCSV()
    
    init() {
        // Start downloading tiles asynchronously
        tileDownloadManager.isDownloading = true
        TileDownloadManager.downloadTiles(for: region) { [tileDownloadManager] in
            tileDownloadManager.isDownloading = false
        }
    }
    
    var categories: [String] {
        let allCategories = Set(pois.flatMap { $0.categories })
        return allCategories.sorted()
    }
    
    var filteredPOIs: [POI] {
        if selectedCategories.isEmpty {
            print("No categories selected, returning empty POI list")
            return []
        } else {
            print("Selected categories: \(selectedCategories)")
            let filtered = pois.filter { poi in
                print("Checking POI: \(poi.title)")
                print("POI categories: \(poi.categories)")
                let matches = !Set(poi.categories).isDisjoint(with: selectedCategories)
                print("POI \(poi.title) matches: \(matches)")
                return matches
            }
            print("Found \(filtered.count) matching POIs")
            return filtered
        }
    }

    var body: some View {
        ZStack {
            MapView(region: $region, 
                   mapType: $mapType, 
                   selectedRoute: $selectedRoute, 
                   pois: pois,
                   filteredPOIs: filteredPOIs) { poi in
                selectedPOI = poi
                showPOIPopup = true
            }
            .edgesIgnoringSafeArea(.all)
            
            // Show loading indicator while downloading tiles
            if tileDownloadManager.isDownloading {
                VStack {
                    ProgressView("Downloading map tiles...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            
            // Control buttons layer
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            showCategoryPicker.toggle()
                        }
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
                        withAnimation {
                            showPOIList.toggle()
                        }
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
                        withAnimation {
                            showRoutePicker.toggle()
                        }
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
            
            // Overlay views
            if showCategoryPicker {
                CategoryPickerView(
                    categories: categories,
                    selectedCategories: $selectedCategories,
                    isPresented: $showCategoryPicker
                )
                .transition(.move(edge: .bottom))
            }

            if showPOIList {
                POIListView(
                    pois: filteredPOIs,
                    selectedCategory: $selectedCategory,
                    categories: categories,
                    onPOISelected: { poi in
                        print("Centering map on POI: \(poi.title) at (\(poi.coordinate.latitude), \(poi.coordinate.longitude))")
                        withAnimation {
                            region = MKCoordinateRegion(
                                center: poi.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                            showPOIList = false
                        }
                    },
                    isPresented: $showPOIList
                )
            }
            
            if showRoutePicker {
                RoutePickerView(
                    routes: routes,
                    selectedRoute: $selectedRoute,
                    isPresented: $showRoutePicker
                )
            }

            if showPOIPopup, let poi = selectedPOI {
                POIDetailView(poi: poi)
                    .onDisappear {
                        selectedPOI = nil
                        showPOIPopup = false
                    }
            }
        }
        .fullScreenCover(isPresented: $showPOIPopup, onDismiss: {
            selectedPOI = nil
        }) {
            if let poi = selectedPOI {
                POIDetailView(poi: poi)
            }
        }
    }
}

class OfflineTileOverlay: MKTileOverlay {
    init() {
        super.init(urlTemplate: nil)
        self.canReplaceMapContent = true
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        // First try to load from disk
        if let tileData = loadTileDataFromDisk(x: path.x, y: path.y, z: path.z) {
            result(tileData, nil)
            return
        }
        
        // If not found, return empty data instead of nil to prevent fallback to Apple Maps
        result(Data(), nil)
    }
    
    private func loadTileDataFromDisk(x: Int, y: Int, z: Int) -> Data? {
        // Try to load from app bundle (blue folder reference)
        let tileName = "\(z)-\(x)-\(y).png"
        if let bundlePath = Bundle.main.path(forResource: tileName, ofType: nil) {
            print("Loading tile from bundle: \(tileName)")
            return try? Data(contentsOf: URL(fileURLWithPath: bundlePath))
        }
        
        // Try to load from documents directory
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let tilePath = documentsDirectory.appendingPathComponent("map_tiles").appendingPathComponent(tileName)
            if let data = try? Data(contentsOf: tilePath) {
                print("Loading tile from documents: \(tileName)")
                return data
            }
        }
        
        return nil
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: MKMapType
    @Binding var selectedRoute: Route?
    let pois: [POI]  // Full list of POIs for lookups
    let filteredPOIs: [POI]  // Filtered list for display
    let onPOITap: (POI) -> Void
    
    // Add zoom level constraints
    private let minZoomLevel: Double = 12  // Maximum zoom out
    private let maxZoomLevel: Double = 18 // Maximum zoom in
    private let minLatitudeDelta: CLLocationDegrees = 0.003   // Most zoomed in
    private let maxLatitudeDelta: CLLocationDegrees = 0.1     // Most zoomed out
    
    // Add map bounds
    private let minLatitude: CLLocationDegrees = 50.8  // Southampton area bounds
    private let maxLatitude: CLLocationDegrees = 51.0
    private let minLongitude: CLLocationDegrees = -1.5
    private let maxLongitude: CLLocationDegrees = -1.3
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Configure map view for interaction
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isUserInteractionEnabled = true
        
        // Enable user location and heading
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        
        // Add offline tile overlay
        let offlineOverlay = OfflineTileOverlay()
        mapView.addOverlay(offlineOverlay, level: .aboveLabels)
        
        // Set map type to satellite to hide default map labels
        mapView.mapType = .satellite
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        var clampedRegion = region
        clampedRegion.span.latitudeDelta = max(minLatitudeDelta, min(maxLatitudeDelta, clampedRegion.span.latitudeDelta))
        clampedRegion.span.longitudeDelta = max(minLatitudeDelta, min(maxLatitudeDelta, clampedRegion.span.longitudeDelta))

        if view.region.center.latitude != clampedRegion.center.latitude ||
            view.region.center.longitude != clampedRegion.center.longitude ||
            view.region.span.latitudeDelta != clampedRegion.span.latitudeDelta ||
            view.region.span.longitudeDelta != clampedRegion.span.longitudeDelta {
            view.setRegion(clampedRegion, animated: true)
        }
        
        view.mapType = mapType
        
        // Update POI annotations using filteredPOIs
        view.removeAnnotations(view.annotations.filter { $0 is MKPointAnnotation })
        let annotations = filteredPOIs.map { poi -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = poi.coordinate
            annotation.title = poi.title
            return annotation
        }
        view.addAnnotations(annotations)
        
        // Update route overlay if selected
        view.removeOverlays(view.overlays.filter { $0 is MKPolyline })
        if let route = selectedRoute {
            loadAndDisplayRoute(route, on: view)
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView
        private let locationManager = CLLocationManager()
        
        init(_ parent: MapView) {
            self.parent = parent
            super.init()
            
            // Request location and heading permissions
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Get the proposed region
            let proposedRegion = mapView.region
            
            // Check if the center is within bounds
            let center = proposedRegion.center
            let span = proposedRegion.span
            
            // Calculate the edges of the visible region
            let northEdge = center.latitude + span.latitudeDelta / 2
            let southEdge = center.latitude - span.latitudeDelta / 2
            let eastEdge = center.longitude + span.longitudeDelta / 2
            let westEdge = center.longitude - span.longitudeDelta / 2
            
            // Check if any edge is outside the bounds
            if northEdge > parent.maxLatitude ||
               southEdge < parent.minLatitude ||
               eastEdge > parent.maxLongitude ||
               westEdge < parent.minLongitude {
                
                // Calculate the constrained center
                var constrainedCenter = center
                constrainedCenter.latitude = max(parent.minLatitude + span.latitudeDelta/2,
                                              min(parent.maxLatitude - span.latitudeDelta/2,
                                                  center.latitude))
                constrainedCenter.longitude = max(parent.minLongitude + span.longitudeDelta/2,
                                               min(parent.maxLongitude - span.longitudeDelta/2,
                                                   center.longitude))
                
                // Create a new region with the constrained center
                let constrainedRegion = MKCoordinateRegion(
                    center: constrainedCenter,
                    span: span
                )
                
                // Set the constrained region
                mapView.setRegion(constrainedRegion, animated: true)
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
                manager.startUpdatingHeading()
            default:
                break
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? MKPointAnnotation else { return nil }
            
            let identifier = "POIAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                // Add detail disclosure button
                let button = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = button
            } else {
                annotationView?.annotation = annotation
            }
            
            // Set marker color based on the POI's first category
            if let markerView = annotationView as? MKMarkerAnnotationView {
                // Find the POI in the full pois array to get its color
                if let poi = parent.pois.first(where: { 
                    $0.title == annotation.title && 
                    $0.coordinate.latitude == annotation.coordinate.latitude &&
                    $0.coordinate.longitude == annotation.coordinate.longitude
                }) {
                    markerView.markerTintColor = UIColor(poi.color)
                }
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            print("Callout accessory tapped")
            guard let annotation = view.annotation as? MKPointAnnotation else {
                print("Failed to get annotation")
                return
            }
            
            // Find the POI in the full pois array
            guard let poi = parent.pois.first(where: { 
                $0.title == annotation.title && 
                $0.coordinate.latitude == annotation.coordinate.latitude &&
                $0.coordinate.longitude == annotation.coordinate.longitude
            }) else {
                print("Failed to find POI for annotation: \(annotation.title ?? "unknown")")
                print("Available POIs:")
                parent.pois.forEach { poi in
                    print("- \(poi.title) at (\(poi.coordinate.latitude), \(poi.coordinate.longitude))")
                }
                return
            }
            
            print("Found POI: \(poi.title)")
            // Call the callback on the main thread
            DispatchQueue.main.async {
                print("Calling onPOITap callback")
                self.parent.onPOITap(poi)
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // Only show the callout, don't trigger the detail view
            print("Annotation selected - showing callout")
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKTileOverlay {
                return MKTileOverlayRenderer(overlay: overlay)
            } else if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    private func loadAndDisplayRoute(_ route: Route, on mapView: MKMapView) {
        guard let gpxPath = Bundle.main.path(forResource: route.gpxFileName, ofType: "gpx"),
              let gpxData = try? Data(contentsOf: URL(fileURLWithPath: gpxPath)) else {
            print("Failed to load GPX file: \(route.gpxFileName)")
            return
        }
        
        do {
            let decoder = XMLDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let gpx = try decoder.decode(GPX.self, from: gpxData)
            
            let coordinates = gpx.track.points.compactMap { point -> CLLocationCoordinate2D? in
                guard let lat = Double(point.lat),
                      let lon = Double(point.lon) else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            
            if !coordinates.isEmpty {
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                mapView.addOverlay(polyline, level: .aboveLabels)
                
                // Optionally zoom to show the entire route
                let region = MKCoordinateRegion(polyline.boundingMapRect)
                mapView.setRegion(region, animated: true)
            }
        } catch {
            print("Failed to decode GPX: \(error)")
        }
    }
}

func downloadVisibleTilesForRegion(_ region: MKCoordinateRegion) {
    // Southampton region
    let minZoom = 12
    let maxZoom = 18
    
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
            // Split categories by semicolon and trim whitespace
            let categories = fields[4].components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let imageName = fields.count > 5 ? fields[5] : nil // Optional 6th field for image name
            let poi = POI(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                title: title,
                description: description,
                categories: categories,
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
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlWithStyle = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: -apple-system;
                        font-size: 17px;
                        color: #000000;
                        line-height: 1.5;
                        margin: 0;
                        padding: 0;
                        background-color: transparent;
                    }
                    img {
                        max-width: 100%;
                        height: auto;
                    }
                </style>
            </head>
            <body>
                \(html)
            </body>
            </html>
        """
        
        // Use a local base URL to prevent network requests
        let baseURL = URL(string: "about:blank")
        uiView.loadHTMLString(htmlWithStyle, baseURL: baseURL)
    }
}

struct CategoryPickerView: View {
    let categories: [String]
    @Binding var selectedCategories: Set<String>
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Text("Filter Points of Interest")
                .font(.title2)
                .padding()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        HStack {
                            Text(category)
                                .font(.body)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { selectedCategories.contains(category) },
                                set: { isOn in
                                    print("Category \(category) toggled to \(isOn)")
                                    if isOn {
                                        selectedCategories.insert(category)
                                    } else {
                                        selectedCategories.remove(category)
                                    }
                                    print("Selected categories now: \(selectedCategories)")
                                }
                            ))
                            .labelsHidden()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                }
                .padding()
            }
            
            HStack {
                Button("Clear All") {
                    print("Clearing all categories")
                    selectedCategories.removeAll()
                }
                .padding()
                
                Button("Close") {
                    isPresented = false
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
}

struct POIListView: View {
    let pois: [POI]
    @Binding var selectedCategory: String
    let categories: [String]
    let onPOISelected: (POI) -> Void
    @Binding var isPresented: Bool
    
    var filteredPOIs: [POI] {
        if selectedCategory == "All" {
            return pois
        } else {
            return pois.filter { $0.categories.contains(selectedCategory) }
        }
    }
    
    var body: some View {
        VStack {
            Text("Points of Interest")
                .font(.title)
                .padding()
            
            Picker("Category", selection: $selectedCategory) {
                Text("All").tag("All")
                ForEach(categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
            
            List(filteredPOIs, id: \.title) { poi in
                Button(action: {
                    print("Selected POI: \(poi.title) at (\(poi.coordinate.latitude), \(poi.coordinate.longitude))")
                    onPOISelected(poi)
                }) {
                    VStack(alignment: .leading) {
                        Text(poi.title)
                            .font(.headline)
                        Text(poi.categories.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            Button("Close") {
                isPresented = false
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
}

struct RoutePickerView: View {
    let routes: [Route]
    @Binding var selectedRoute: Route?
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Text("Select Walking Route")
                .font(.title)
                .padding()
            
            List(routes, id: \.name) { route in
                Button(action: {
                    selectedRoute = route
                    isPresented = false
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
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("No Route")
                }
                .foregroundColor(.red)
            }
            .padding()
            
            Button("Cancel") {
                isPresented = false
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
}

#Preview {
    ContentView()
}

