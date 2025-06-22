//
//  ContentView.swift
//  pathvoice
//
//  Created by Ayush Pai on 6/21/25.
//

import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var placesService = PlacesAPIService()
    @StateObject private var aiManager = AIManager()
    @StateObject private var speechService = SpeechService()
    @State private var autoUpdateTimer: Timer?
    @State private var currentTopAttractionId: String?
    @State private var isTourActive = false
    @State private var isLoadingContent = false
    @State private var showingSettings = false
    @State private var pollingInterval: Double = 60.0
    @State private var searchRadius: Double = 400.0

    var body: some View {
        NavigationView {
            if isTourActive {
                // Tour Active View
                ZStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Current Location Display
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                    
                                    Text("Current Location: \(locationManager.locationName)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                }
                                
                                // Live Map
                                if let location = locationManager.location {
                                    VStack(spacing: 8) {
                                        Map(position: .constant(.userLocation(fallback: .automatic))) {
                                            UserAnnotation()
                                            
                                            // Add attraction pin if available and audio is playing
                                            if let topAttraction = placesService.places.first, speechService.isAudioPlaying {
                                                Annotation(
                                                    topAttraction.displayName.text,
                                                    coordinate: CLLocationCoordinate2D(
                                                        latitude: topAttraction.location.latitude,
                                                        longitude: topAttraction.location.longitude
                                                    )
                                                ) {
                                                    VStack(spacing: 0) {
                                                        Image(systemName: "mappin.circle.fill")
                                                            .foregroundColor(.red)
                                                            .font(.title)
                                                            .background(Color.white)
                                                            .clipShape(Circle())
                                                        
                                                        Text(topAttraction.displayName.text)
                                                            .font(.caption)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.white)
                                                            .foregroundColor(.black)
                                                            .cornerRadius(8)
                                                            .shadow(radius: 2)
                                                    }
                                                }
                                            }
                                        }
                                        .mapStyle(.standard)
                                        .frame(width: UIScreen.main.bounds.width - 80, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                        
                                        // Coordinates Display
                                        HStack(spacing: 20) {
                                            HStack(spacing: 4) {
                                                Text("Lat")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .textCase(.uppercase)
                                                    .tracking(0.5)
                                                
                                                Text("\(location.latitude, specifier: "%.4f")")
                                                    .font(.system(.caption, design: .monospaced))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Divider()
                                                .frame(height: 12)
                                            
                                            HStack(spacing: 4) {
                                                Text("Lng")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .textCase(.uppercase)
                                                    .tracking(0.5)
                                                
                                                Text("\(location.longitude, specifier: "%.4f")")
                                                    .font(.system(.caption, design: .monospaced))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                } else {
                                    // Placeholder when location not available
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: UIScreen.main.bounds.width - 80, height: 200)
                                        .overlay(
                                            VStack {
                                                Image(systemName: "location.slash")
                                                    .foregroundColor(.gray)
                                                    .font(.largeTitle)
                                                Text("Getting location...")
                                                    .foregroundColor(.gray)
                                                    .font(.caption)
                                            }
                                        )
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                            )
                            
                            if let errorMessage = placesService.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .padding()
                            }
                            
                            // Content Area - Either Loading or Attraction
                            if isLoadingContent {
                                // Loading Screen
                                LoadingView()
                            } else if let topAttraction = placesService.places.first {
                                // Single Attraction View
                                VStack(alignment: .leading, spacing: 16) {
                                    // Attraction Image and Info
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Photo
                                        if let photos = topAttraction.photos, !photos.isEmpty,
                                           let photoURL = placesService.getPhotoURL(for: photos[0], maxWidth: 400) {
                                            AsyncImage(url: photoURL) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.gray.opacity(0.3))
                                                    .overlay(
                                                        Image(systemName: "photo")
                                                            .foregroundColor(.gray)
                                                            .font(.largeTitle)
                                                    )
                                            }
                                            .frame(width: UIScreen.main.bounds.width - 80, height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            // Placeholder when no photo
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: UIScreen.main.bounds.width - 80, height: 200)
                                                .overlay(
                                                    Image(systemName: "mappin.circle.fill")
                                                        .foregroundColor(.red)
                                                        .font(.system(size: 50))
                                                )
                                        }
                                        
                                        // Attraction Details
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(topAttraction.displayName.text)
                                                        .font(.title2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.primary)
                                                    
                                                    Text(topAttraction.formattedAddress)
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                // Navigation Button
                                                Button(action: {
                                                    openDirections(to: topAttraction)
                                                }) {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "location.circle.fill")
                                                            .foregroundColor(.blue)
                                                            .font(.title2)
                                                        
                                                        Text("Navigate")
                                                            .font(.caption)
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                            }
                                            
                                            if let primaryType = topAttraction.primaryType {
                                                Text(primaryType)
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.blue)
                                                    .cornerRadius(16)
                                            }
                                        }
                                    }
                                    
                                    // AI Tour Guide Section
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("AI Tour Guide")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            // Speech Controls
                                            if !aiManager.currentTourGuideText.isEmpty {
                                                if speechService.isSpeaking {
                                                    Button(action: {
                                                        speechService.pauseSpeaking()
                                                    }) {
                                                        Image(systemName: "pause.circle.fill")
                                                            .foregroundColor(.orange)
                                                            .font(.title2)
                                                    }
                                                } else if speechService.isAudioPlaying {
                                                    Button(action: {
                                                        speechService.resumeSpeaking()
                                                    }) {
                                                        Image(systemName: "play.circle.fill")
                                                            .foregroundColor(.green)
                                                            .font(.title2)
                                                    }
                                                } else {
                                                    Button(action: {
                                                        speechService.speakText(aiManager.currentTourGuideText)
                                                    }) {
                                                        Image(systemName: "arrow.clockwise.circle.fill")
                                                            .foregroundColor(.blue)
                                                            .font(.title2)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if aiManager.isLoading {
                                            ProgressView("Generating tour guide...")
                                                .frame(maxWidth: .infinity, alignment: .center)
                                        } else if !aiManager.currentTourGuideText.isEmpty {
                                            Text(aiManager.currentTourGuideText)
                                                .padding()
                                                .background(Color.green.opacity(0.1))
                                                .cornerRadius(12)
                                                .font(.body)
                                        }
                                        
                                        if let aiErrorMessage = aiManager.errorMessage {
                                            Text(aiErrorMessage)
                                                .foregroundColor(.red)
                                                .font(.caption)
                                        }
                                        
                                        if let speechErrorMessage = speechService.errorMessage {
                                            Text(speechErrorMessage)
                                                .foregroundColor(.red)
                                                .font(.caption)
                                        }
                                    }
                                    .padding()
                                    .background(Color.green.opacity(0.05))
                                    .cornerRadius(16)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .opacity(speechService.isAudioPlaying ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.5), value: speechService.isAudioPlaying)
                            }
                            
                            // Stop Tour Button
                            Button("Stop Tour Guide") {
                                stopTour()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .padding()
                        }
                        .padding()
                    }
                    
                    // Loading Overlay
                    if isLoadingContent {
                        LoadingView()
                    }
                }
                .navigationTitle("PathVoice Tour")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                // Home Screen
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App Icon/Logo
                    VStack(spacing: 20) {
                        Image(systemName: "map.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.blue)
                        
                        Text("PathVoice")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Your AI Tour Guide")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Start Tour Button
                    VStack(spacing: 20) {
                        Button(action: {
                            startTour()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("Start Tour Guide")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                        }
                        .disabled(locationManager.location == nil)
                        
                        if locationManager.location == nil {
                            Text("Getting your location...")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .navigationTitle("PathVoice")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(pollingInterval: $pollingInterval, searchRadius: $searchRadius)
        }
        .onReceive(placesService.$places) { places in
            // Check if the top attraction has changed
            if let topAttraction = places.first {
                let newAttractionId = "\(topAttraction.displayName.text)_\(topAttraction.formattedAddress)"
                if newAttractionId != currentTopAttractionId {
                    // Top attraction has changed, generate new AI content
                    currentTopAttractionId = newAttractionId
                    aiManager.autoGenerateForTopAttraction(places)
                }
            }
        }
        .onReceive(placesService.$isLoading) { loading in
            isLoadingContent = loading
        }
        .onReceive(aiManager.$isLoading) { loading in
            if loading {
                isLoadingContent = true
            }
        }
        .onReceive(speechService.$isAudioPlaying) { isPlaying in
            if isPlaying {
                // Hide loading when audio starts playing
                isLoadingContent = false
            }
        }
        .onAppear {
            // Connect speech service to AI manager
            aiManager.setSpeechService(speechService)
        }
    }
    
    private func startTour() {
        isTourActive = true
        isLoadingContent = true
        if let loc = locationManager.location {
            placesService.fetchNearbyTouristAttractions(coordinate: loc, radius: searchRadius)
        }
        startAutoUpdateTimer()
    }
    
    private func stopTour() {
        isTourActive = false
        isLoadingContent = false
        stopAutoUpdateTimer()
        speechService.stopSpeaking()
    }
    
    private func startAutoUpdateTimer() {
        // Start timer to update every minute
        autoUpdateTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { _ in
            if let loc = locationManager.location {
                isLoadingContent = true
                placesService.fetchNearbyTouristAttractions(coordinate: loc, radius: searchRadius)
            }
        }
    }
    
    private func stopAutoUpdateTimer() {
        autoUpdateTimer?.invalidate()
        autoUpdateTimer = nil
    }
    
    private func openDirections(to attraction: Place) {
        let latitude = attraction.location.latitude
        let longitude = attraction.location.longitude
        let name = attraction.displayName.text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let address = attraction.formattedAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Try Apple Maps first with attraction name, then coordinates as fallback
        let appleMapsURLWithName = "http://maps.apple.com/?daddr=\(name)&dirflg=d"
        let appleMapsURLWithCoords = "http://maps.apple.com/?daddr=\(latitude),\(longitude)&dirflg=d"
        
        // Try to open Apple Maps with attraction name first
        if let url = URL(string: appleMapsURLWithName) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to Apple Maps with coordinates
        if let url = URL(string: appleMapsURLWithCoords) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Try Google Maps with attraction name
        let googleMapsURLWithName = "comgooglemaps://?daddr=\(name)&directionsmode=driving"
        let googleMapsURLWithCoords = "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=driving"
        let googleMapsWebURLWithName = "https://www.google.com/maps/dir/?api=1&destination=\(name)"
        let googleMapsWebURLWithCoords = "https://www.google.com/maps/dir/?api=1&destination=\(latitude),\(longitude)"
        
        // Try to open Google Maps app with attraction name
        if let url = URL(string: googleMapsURLWithName) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to Google Maps app with coordinates
        if let url = URL(string: googleMapsURLWithCoords) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to Google Maps web with attraction name
        if let url = URL(string: googleMapsWebURLWithName) {
            UIApplication.shared.open(url)
            return
        }
        
        // Final fallback to Google Maps web with coordinates
        if let url = URL(string: googleMapsWebURLWithCoords) {
            UIApplication.shared.open(url)
        }
    }
}

struct SettingsView: View {
    @Binding var pollingInterval: Double
    @Binding var searchRadius: Double
    @Environment(\.dismiss) private var dismiss
    
    private let pollingOptions: [Double] = [30, 60, 120, 300] // 30s, 1min, 2min, 5min
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tour Settings")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Polling Interval")
                            .font(.headline)
                        
                        Text("How often the app checks for new nearby attractions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Polling Interval", selection: $pollingInterval) {
                            ForEach(pollingOptions, id: \.self) { interval in
                                Text(formatPollingInterval(interval))
                                    .tag(interval)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Search Radius")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search Radius")
                            .font(.headline)
                        
                        Text("The radius in meters to search for nearby attractions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $searchRadius, in: 100...1000, step: 100)
                        
                        Text("\(Int(searchRadius)) meters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
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
    
    private func formatPollingInterval(_ interval: Double) -> String {
        switch interval {
        case 30:
            return "30s"
        case 60:
            return "1m"
        case 120:
            return "2m"
        case 300:
            return "5m"
        default:
            return "\(Int(interval))s"
        }
    }
}

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 12) {
                Text("Discovering nearby attractions...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Your AI tour guide is preparing")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ContentView()
}
