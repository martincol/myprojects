//
//  ContentView.swift
//  TestiOSApp
//
//  Created by Martin Collins on 26/04/2025.
//

typealias SScrollView = SwiftUI.ScrollView

import SwiftUI
import MapKit
import CoreLocation
import Foundation
import XMLCoder
import WebKit
import AVFoundation

// Add HeadingViewModel class
import CoreLocation
import Combine

class HeadingViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double = 0.0
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization() // Request permission
        
        // Check if heading is available
        if CLLocationManager.headingAvailable() {
            self.locationManager.startUpdatingHeading()
        } else {
            print("Device heading is not available.")
            // Optionally, provide a default heading or an error state
            // self.heading = -1 // Example to indicate unavailability
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Use magneticHeading for compass-like behavior
        // trueHeading points to geographic North Pole, magneticHeading to magnetic North Pole
        // Consider device orientation if you want the compass to always point "up" relative to the device screen
        DispatchQueue.main.async {
            self.heading = newHeading.magneticHeading
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        // Handle errors, e.g., by stopping updates or notifying the user
    }
    
    // It's good practice to stop updates when they're no longer needed,
    // though for a persistent compass, you might not call this often.
    deinit {
        self.locationManager.stopUpdatingHeading()
    }
}

// Add CompassView struct
struct CompassView: View {
    @ObservedObject var viewModel: HeadingViewModel
    let compassSize: CGFloat = 80 // Increased size for better readability

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.gray.opacity(0.2))
                .shadow(radius: 3)

            // Static Cardinal Directions
            Text("N")
                .font(.caption.bold())
                .foregroundColor(.black)
                .offset(y: -compassSize / 2.5)
            Text("S")
                .font(.caption.bold())
                .foregroundColor(.black)
                .offset(y: compassSize / 2.5)
            Text("E")
                .font(.caption.bold())
                .foregroundColor(.black)
                .offset(x: compassSize / 2.5)
            Text("W")
                .font(.caption.bold())
                .foregroundColor(.black)
                .offset(x: -compassSize / 2.5)

            // Rotating Needle
            Image(systemName: "arrowtriangle.up.fill") // A simple arrow for North
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: compassSize * 0.2, height: compassSize * 0.4)
                .foregroundColor(.red) // Red for North part of needle
                .offset(y: -compassSize * 0.15) // Adjust position to pivot correctly
                .rotationEffect(.degrees(viewModel.heading)) // Corrected rotation

            // Optional: Smaller arrow for the South end of the needle
            Image(systemName: "arrowtriangle.down.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: compassSize * 0.2, height: compassSize * 0.4)
                .foregroundColor(.gray) // Gray for South part of needle
                .offset(y: compassSize * 0.15) // Adjust position
                .rotationEffect(.degrees(viewModel.heading)) // Corrected rotation


        }
        .frame(width: compassSize, height: compassSize)
    }
}

struct POI: Equatable {
    let coordinate: CLLocationCoordinate2D
    let title: String
    let description: String
    let directions: String?
    let audio: String?  // Add new audio field
    let categories: [String]
    let imageName: String? // Optional image name
    
    static func == (lhs: POI, rhs: POI) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.directions == rhs.directions &&
               lhs.audio == rhs.audio &&  // Add to equality check
               lhs.categories == rhs.categories &&
               lhs.imageName == rhs.imageName
    }
}

// Add color mapping for categories
extension POI {
    var color: Color {
        // Use the first category for color
        guard let firstCategory = categories.first else {
            return .pink
        }
        
        switch firstCategory {
        case "Walking Tour":
            return .blue
        case "Pubs":
            return .green
        case "Historical":
            return .brown
        case "Shopping":
            return .white
        case "Restaurants":
            return .red
        case "Activities":
            return .white
        case "Transport":
            return .gray
        case "Cafes":
            return .yellow
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

struct HTMLTextView: UIViewRepresentable {
    let html: String
    @Binding var contentHeight: CGFloat
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        //configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        //webView.isOpaque = false
        //webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false  // Disable internal scrolling
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
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
                        margin: 5;
                        padding: 5;
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLTextView
        
        init(_ parent: HTMLTextView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Get the content height after the page loads
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { (height, error) in
                if let height = height as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.contentHeight = height
                    }
                }
            }
        }
    }
}

struct POIDetailView: View {
    let poi: POI
    @Environment(\.dismiss) private var dismiss
    @State private var htmlContentHeight: CGFloat = 0
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var progress: Double = 0
    @State private var timer: Timer?
    @State public var audioPlayerDelegate: AudioPlayerDelegate? // Strong reference
    
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
                    
                    // Audio player if available
                    if let audioFileName = poi.audio {
                        VStack(spacing: 8) {
                            HStack {
                                // Rewind button
                                Button(action: {
                                    if let player = audioPlayer {
                                        let newTime = max(0, player.currentTime - 30)
                                        player.currentTime = newTime
                                        progress = newTime / player.duration
                                    }
                                }) {
                                    Image(systemName: "gobackward.30")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                                .padding(.trailing, 8)
                                
                                Button(action: {
                                    if isPlaying {
                                        audioPlayer?.pause()
                                        timer?.invalidate()
                                        timer = nil
                                    } else {
                                        do {
                                            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                                            try AVAudioSession.sharedInstance().setActive(true)
                                            if let player = audioPlayer {
                                                
                                                player.play()
                                                
                                                // Start progress timer
                                                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                                                    if let player = audioPlayer {
                                                        progress = player.currentTime / player.duration
                                                        if !player.isPlaying {
                                                            timer?.invalidate()
                                                            timer = nil
                                                            isPlaying = false
                                                        }
                                                    }
                                                }
                                            } else {
                                            }
                                        } catch {
                                            print("Failed to play audio: \(error)")
                                        }
                                    }
                                    isPlaying.toggle()
                                }) {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(.blue)
                                }
                                
                                // Forward button
                                Button(action: {
                                    if let player = audioPlayer {
                                        let newTime = min(player.duration, player.currentTime + 30)
                                        player.currentTime = newTime
                                        progress = newTime / player.duration
                                    }
                                }) {
                                    Image(systemName: "goforward.30")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                                .padding(.leading, 8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ProgressView(value: progress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .onAppear {
                            setupAudioPlayer(fileName: audioFileName)
                        }
                        .onDisappear {
                            timer?.invalidate()
                            timer = nil
                            audioPlayer?.stop()
                            try? AVAudioSession.sharedInstance().setActive(false)
                        }
                    }
                    
                    // Directions if available
                    if let directions = poi.directions {
                        Text("Walking Tour Directions: \(directions)")
                            .font(.body)
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                    }
                    
                    // Description
                    if poi.description.contains("<") && poi.description.contains(">") {
                        HTMLTextView(html: poi.description, contentHeight: $htmlContentHeight)
                            .frame(maxWidth: .infinity)
                            .frame(height: htmlContentHeight)
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
                        print("Done button pressed")
                        timer?.invalidate()
                        timer = nil
                        audioPlayer?.stop()
                        try? AVAudioSession.sharedInstance().setActive(false)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func setupAudioPlayer(fileName: String) {
        let components = fileName.components(separatedBy: ".")
        guard components.count == 2 else {
            print("Invalid audio filename format: \(fileName)")
            return
        }
        
        let name = components[0]
        let ext = components[1].lowercased() // Convert extension to lowercase
        
        guard let path = Bundle.main.path(forResource: name, ofType: ext) else  {
            return
        }
                
        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            // Create URL and validate file exists
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: path) else {
                print("Audio file does not exist at path: \(path)")
                return
            }
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            
            guard let player = audioPlayer else {
                print("Failed to create audio player")
                return
            }
            
            // Configure audio player
            player.volume = 1.0
            player.numberOfLoops = 0
            player.enableRate = true
            player.rate = 1.0
            
            // Set up delegate to handle playback completion
            // Create and hold a strong reference to the delegate
            self.audioPlayerDelegate = AudioPlayerDelegate(isPlaying: $isPlaying, progress: $progress)
            player.delegate = self.audioPlayerDelegate
            
            let prepared = player.prepareToPlay()
            print("Audio player prepared to play: \(prepared)")
        } catch {
            print("Failed to setup audio: \(error)")
        }
    }
}

// Add AudioPlayerDelegate class
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    @Binding var isPlaying: Bool
    @Binding var progress: Double
    
    init(isPlaying: Binding<Bool>, progress: Binding<Double>) {
        _isPlaying = isPlaying
        _progress = progress
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        progress = 0
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

// Update XML decoding structures
struct POIXML: Codable {
    let pois: [POIEntry]
    
    enum CodingKeys: String, CodingKey {
        case pois = "poi"
    }
}

struct POIEntry: Codable {
    let title: String
    let latitude: String
    let longitude: String
    let description: String?
    let directions: String?
    let audio: String?  // Add new audio field
    let categories: Categories?
    let image: String?
    let sections: Sections?
    
    struct Categories: Codable {
        let category: [String]
    }
    
    struct Sections: Codable {
        let section: [Section]
    }
    
    struct Section: Codable {
        let name: String
        let content: String
        
        enum CodingKeys: String, CodingKey {
            case name
            case content = ""
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            content = try container.decode(String.self, forKey: .content)
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
    @State private var shouldUpdateRegion = true // Flag to control region updates

    // Add AppStorage for first launch tracking
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var showWelcomeView: Bool = false

    @StateObject private var headingViewModel = HeadingViewModel()

    let pois = loadPOIsFromXML()
    let routes = loadRoutesFromXML()
    
    init() {
        // Start downloading tiles asynchronously 
        //tileDownloadManager.isDownloading = true
        //TileDownloadManager.downloadTiles(for: region) { [tileDownloadManager] in
        //    tileDownloadManager.isDownloading = false
        //}
    }
    
    var categories: [String] {
        let allCategories = Set(pois.flatMap { $0.categories })
        return allCategories.sorted()
    }
    
    var filteredPOIs: [POI] {
        if selectedCategories.isEmpty {
            return []
        } else {
            let filtered = pois.filter { poi in
                let matches = !Set(poi.categories).isDisjoint(with: selectedCategories)
                return matches
            }
            return filtered
        }
    }

    var body: some View {
        ZStack {
            MapView(region: $region, 
                   mapType: $mapType, 
                   selectedRoute: $selectedRoute, 
                   pois: pois,
                   filteredPOIs: filteredPOIs,
                   shouldUpdateRegion: $shouldUpdateRegion) { poi in
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
                        shouldUpdateRegion = true
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
            
            // Add CompassView to the bottom-right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    CompassView(viewModel: headingViewModel)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
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
        .onAppear {
            if !hasLaunchedBefore {
                showWelcomeView = true
                hasLaunchedBefore = true
            }
        }
        .sheet(isPresented: $showWelcomeView) {
            WelcomeView(isPresented: $showWelcomeView)
                .onDisappear {
                    // This onDisappear on WelcomeView itself might not be strictly necessary
                    // if the sheet's isPresented binding handles dismissal correctly,
                    // but it's good for ensuring the state is reset if needed.
                    // showWelcomeView = false // Already handled by binding
                }
        }
    }
}

class OfflineTileOverlay: MKTileOverlay {
    // Define the bounds of our available tiles - Hard-coded to Southampton area
    static let minLatitude: CLLocationDegrees = 50.85  // Southampton area bounds - tighter constraints
    static let maxLatitude: CLLocationDegrees = 50.95
    static let minLongitude: CLLocationDegrees = -1.45
    static let maxLongitude: CLLocationDegrees = -1.35
    
    // Track which tiles are available
    private var availableTiles = Set<String>()
    
    init() {
        super.init(urlTemplate: nil)
        self.canReplaceMapContent = true
        self.tileSize = CGSize(width: 256, height: 256)
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
    
    // Static method to get bounds
    static func getBounds() -> MKCoordinateRegion {
        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: maxLatitude - minLatitude,
            longitudeDelta: maxLongitude - minLongitude
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func loadTileDataFromDisk(x: Int, y: Int, z: Int) -> Data? {
        // Try to load from app bundle (blue folder reference)
        let tileName = "\(z)-\(x)-\(y).png"
        if let bundlePath = Bundle.main.path(forResource: tileName, ofType: nil) {
            //print("Loading tile from bundle: \(tileName)")
            return try? Data(contentsOf: URL(fileURLWithPath: bundlePath))
        }
        
        // Try to load from documents directory
        //if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        //    let tilePath = documentsDirectory.appendingPathComponent("map_tiles").appendingPathComponent(tileName)
        //    if let data = try? Data(contentsOf: tilePath) {
        //        print("Loading tile from documents: \(tileName)")
        //        return data
        //    }
        //}
        
        return nil
    }
}

func tileForCoordinate(latitude: Double, longitude: Double, zoom: Int) -> (x: Int, y: Int) {
    let n = pow(2.0, Double(zoom))
    let radLat = latitude * .pi / 180.0
    
    let x = Int((longitude + 180.0) / 360.0 * n)
    let y = Int((1.0 - log(tan(radLat) + 1.0 / cos(radLat)) / .pi) / 2.0 * n)
    
    return (x: x, y: y)
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: MKMapType
    @Binding var selectedRoute: Route?
    @Binding var shouldUpdateRegion: Bool
    let pois: [POI]  // Full list of POIs for lookups
    let filteredPOIs: [POI]  // Filtered list for display
    let onPOITap: (POI) -> Void
    
    // Add zoom level constraints
    private let minLatitudeDelta: CLLocationDegrees = 0.01   // Most zoomed in (increased from 0.003)
    private let maxLatitudeDelta: CLLocationDegrees = 0.1     // Most zoomed out
    
    // Store initial region for bounds
    private let initialRegion: MKCoordinateRegion
    
    init(region: Binding<MKCoordinateRegion>, 
         mapType: Binding<MKMapType>, 
         selectedRoute: Binding<Route?>, 
         pois: [POI], 
         filteredPOIs: [POI],
         shouldUpdateRegion: Binding<Bool> = .constant(true),
         onPOITap: @escaping (POI) -> Void) {
        self._region = region
        self._mapType = mapType
        self._selectedRoute = selectedRoute
        self._shouldUpdateRegion = shouldUpdateRegion
        self.pois = pois
        self.filteredPOIs = filteredPOIs
        self.onPOITap = onPOITap
        self.initialRegion = region.wrappedValue
    }
    
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
        
        // Disable annotation clustering
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "POIAnnotation")
        
        // Set map type to standard (will be covered by our overlay)
        mapView.mapType = .standard
        
        // Add offline tile overlay
        let offlineOverlay = OfflineTileOverlay()
        offlineOverlay.canReplaceMapContent = true  // This ensures our overlay replaces the base map
        mapView.addOverlay(offlineOverlay, level: .aboveLabels)
        
        // Set initial region from ContentView
        mapView.setRegion(initialRegion, animated: false)
        
        // Create a boundary region based on the initial region
        let center = initialRegion.center
        let span = initialRegion.span
        
        let boundaryRegion = MKCoordinateRegion(
            center: center,
            span: span
        )
        
        // Set camera bounds
        mapView.setCameraBoundary(
            MKMapView.CameraBoundary(coordinateRegion: boundaryRegion),
            animated: false
        )
        
        // Set zoom restrictions
        let minDistance = 1000.0
        let maxDistance = 15000.0
        let zoomRange = MKMapView.CameraZoomRange(
            minCenterCoordinateDistance: minDistance,
            maxCenterCoordinateDistance: maxDistance
        )
        mapView.setCameraZoomRange(zoomRange, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        if shouldUpdateRegion {
            view.setRegion(region, animated: true)
            DispatchQueue.main.async {
                self.shouldUpdateRegion = false
            }
        }
        
        view.mapType = mapType
        
        // Clear existing route-specific annotations and overlays first
        view.removeOverlays(view.overlays.filter { $0 is MKPolyline })
        let routeAnnotations = view.annotations.filter { annotation in
            return annotation is DirectionalArrowAnnotation ||
                   (annotation as? MKPointAnnotation)?.title?.hasPrefix("Start:") == true
        }
        view.removeAnnotations(routeAnnotations)
        
        // Update POI annotations using filteredPOIs
        // Remove only POI annotations before adding new ones to avoid flicker/duplication
        let poiAnnotations = view.annotations.filter { annotation in
            // Check if it's a POI annotation (not user location, not route start, not arrow)
            return !(annotation is MKUserLocation) &&
                   !((annotation as? MKPointAnnotation)?.title?.hasPrefix("Start:") == true) &&
                   !(annotation is DirectionalArrowAnnotation)
        }
        view.removeAnnotations(poiAnnotations)
        
        let newPoiAnnotations = filteredPOIs.map { poi -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = poi.coordinate
            annotation.title = poi.title
            return annotation
        }
        view.addAnnotations(newPoiAnnotations)
        
        // Update route overlay if selected
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
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
                renderer.alpha = 1.0  // Ensure our overlay is fully opaque
                return renderer
            } else if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
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
            // Don't customize user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            // Handle directional arrow annotation
            if let arrowAnnotation = annotation as? DirectionalArrowAnnotation {
                let identifier = "DirectionalArrow"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                
                // Create arrow image
                let arrowImage = UIImage(systemName: "arrow.up.circle.fill")?
                    .withTintColor(.blue, renderingMode: .alwaysOriginal)
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .bold))
                
                annotationView?.image = arrowImage
                annotationView?.transform = CGAffineTransform(rotationAngle: CGFloat(arrowAnnotation.bearing * .pi / 180))
                annotationView?.layer.zPosition = arrowAnnotation.zPosition
                return annotationView
            }
            
            // Handle route start point annotation
            if let pointAnnotation = annotation as? MKPointAnnotation,
               pointAnnotation.title?.hasPrefix("Start:") == true {
                let identifier = "RouteStartPoint"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                
                annotationView?.annotation = annotation
                annotationView?.canShowCallout = true
                annotationView?.markerTintColor = .green
                annotationView?.glyphImage = UIImage(systemName: "flag.fill")?
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .bold))
                annotationView?.displayPriority = .required
                annotationView?.layer.zPosition = 1.0  // Set zPosition below arrow but above other annotations
                return annotationView
            }
            
            // Handle POI annotations
            guard let annotation = annotation as? MKPointAnnotation else { return nil }
            
            let identifier = "POIAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            
            // Configure the annotation view
            annotationView?.annotation = annotation
            annotationView?.canShowCallout = true
            //annotationView?.titleVisibility = .hidden  // Hide the permanent title
            //annotationView?.subtitleVisibility = .hidden
            
            // Add detail disclosure button
            let button = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = button
            
            // Disable clustering for this annotation
            annotationView?.clusteringIdentifier = nil
            annotationView?.displayPriority = .required
            
            // Set marker color based on the POI's first category
            if let markerView = annotationView {
                // Find the POI in the full pois array to get its color
                if let poi = parent.pois.first(where: { 
                    $0.title == annotation.title && 
                    $0.coordinate.latitude == annotation.coordinate.latitude &&
                    $0.coordinate.longitude == annotation.coordinate.longitude
                }) {
                    markerView.markerTintColor = UIColor(poi.color)
                }
            }
            
            annotationView?.layer.zPosition = 0.0  // Set zPosition below route annotations
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
                // Add the route polyline
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                mapView.addOverlay(polyline, level: .aboveLabels)
                
                // Add a marker at the starting point
                let startPoint = coordinates[0]
                let startAnnotation = MKPointAnnotation()
                startAnnotation.coordinate = startPoint
                startAnnotation.title = "Start: \(route.name)"
                mapView.addAnnotation(startAnnotation)
                
                // Add directional arrow if we have at least 2 points
                if coordinates.count >= 2 {
                    // Place arrow at the end of first segment (second point)
                    let firstPoint = coordinates[0]
                    let secondPoint = coordinates[1]
                    
                    // Calculate bearing between points
                    let bearing = calculateBearing(from: firstPoint, to: secondPoint)
                    
                    // Create arrow annotation at second point
                    let arrowAnnotation = DirectionalArrowAnnotation(
                        coordinate: secondPoint,
                        bearing: bearing
                    )
                    mapView.addAnnotation(arrowAnnotation)
                }
                
                // Optionally zoom to show the entire route
                //let region = MKCoordinateRegion(polyline.boundingMapRect)
                //mapView.setRegion(region, animated: true)
            }
        } catch {
            print("Failed to decode GPX: \(error)")
        }
    }
    
    // Add DirectionalArrowAnnotation class
    class DirectionalArrowAnnotation: NSObject, MKAnnotation {
        let coordinate: CLLocationCoordinate2D
        let bearing: Double
        let zPosition: CGFloat = 2.0  // Increase zPosition to be above all other annotations
        
        init(coordinate: CLLocationCoordinate2D, bearing: Double) {
            self.coordinate = coordinate
            self.bearing = bearing
            super.init()
        }
    }
    
    // Add helper function to calculate bearing
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        
        return bearing * 180 / .pi
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
           // downloadTile(x: tile.x, y: tile.y, zoom: zoom)
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

// func downloadTile(x: Int, y: Int, zoom: Int) {
//     print("\(zoom),\(x),\(y)")
// }

// Helper to split a CSV line, handling quoted fields
// func splitCSVLine(_ line: String) -> [String] {
//     var results: [String] = []
//     var value = ""
//     var insideQuotes = false
//     var iterator = line.makeIterator()
//     while let char = iterator.next() {
//         if char == "\"" {
//             insideQuotes.toggle()
//         } else if char == "," && !insideQuotes {
//             results.append(value)
//             value = ""
//         } else {
//             value.append(char)
//         }
//     }
//     results.append(value)
//     return results.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") }
// }

// Update loadPOIsFromXML with better error handling
func loadPOIsFromXML() -> [POI] {
    guard let path = Bundle.main.path(forResource: "pois", ofType: "xml"),
          let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        print("XML file not found")
        return []
    }
    
    do {
        let decoder = XMLDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        
        let xmlData = try decoder.decode(POIXML.self, from: data)
        
        return xmlData.pois.compactMap { entry -> POI? in
            guard let lat = Double(entry.latitude),
                  let lon = Double(entry.longitude) else {
                print("Invalid coordinates for POI: \(entry.title)")
                return nil
            }
            
            // Convert XML entry to POI
            let categories = entry.categories?.category ?? []
            let description = entry.description ?? ""
            let directions = entry.directions
            let audio = entry.audio
            
            // If there are sections, combine them into a formatted description
            var finalDescription = description
            if let sections = entry.sections?.section {
                let sectionsHTML = sections.map { section in
                    "<h3>\(section.name)</h3><p>\(section.content)</p>"
                }.joined(separator: "")
                finalDescription = sectionsHTML
            }
            
            return POI(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                title: entry.title,
                description: finalDescription,
                directions: directions,
                audio: audio,
                categories: categories,
                imageName: entry.image
            )
        }
    } catch {
        print("Failed to decode XML: \(error)")
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("Key not found: \(key.stringValue), context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("Type mismatch: expected \(type), context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value not found: expected \(type), context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error")
            }
        }
        return []
    }
}

// New function to load routes from XML
func loadRoutesFromXML() -> [Route] {
    guard let path = Bundle.main.path(forResource: "routes", ofType: "xml"),
          let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        print("routes.xml file not found")
        return []
    }

    do {
        let decoder = XMLDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys // Match XML element names
        let xmlData = try decoder.decode(RoutesXML.self, from: data)

        return xmlData.route.compactMap { entry -> Route? in
            guard let distanceDouble = Double(entry.distance) else {
                print("Invalid distance format for route: \(entry.name) - value: \(entry.distance)")
                return nil
            }
            return Route(
                name: entry.name,
                description: entry.description,
                gpxFileName: entry.gpxFileName,
                distance: distanceDouble,
                duration: entry.duration
            )
        }
    } catch {
        print("Failed to decode routes.xml: \(error)")
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("Key not found: \(key.stringValue), context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("Type mismatch: expected \(type), context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value not found: expected \(type), context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error")
            }
        }
        return []
    }
}

// New structs for parsing routes.xml
struct RoutesXML: Codable {
    let route: [RouteEntryXML]
}

struct RouteEntryXML: Codable {
    let name: String
    let description: String
    let gpxFileName: String
    let distance: String // Read as String first, then convert
    let duration: String
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
        .onAppear {
            //shouldUpdateRegion = false
        }
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
        .onAppear {
            //shouldUpdateRegion = false
        }
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
        .onAppear {
            //shouldUpdateRegion = false
        }
    }
}

#Preview {
    ContentView()
}

