//
//  ContentView.swift
//  pathvoice
//
//  Created by Ayush Pai on 6/21/25.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var placesService = PlacesAPIService()
    @StateObject private var aiManager = AIManager()
    @State private var autoUpdateTimer: Timer?
    @State private var currentTopAttractionId: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let loc = locationManager.location {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Current Location:")
                                .font(.headline)
                            Text("Latitude: \(loc.latitude, specifier: "%.6f")")
                            Text("Longitude: \(loc.longitude, specifier: "%.6f")")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        Button("Find Nearby Tourist Attractions") {
                            placesService.fetchNearbyTouristAttractions(coordinate: loc, radius: 400.0)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(placesService.isLoading)
                        
                        if placesService.isLoading {
                            ProgressView("Searching for attractions...")
                        }
                        
                        if let errorMessage = placesService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        // Single Attraction View
                        if let topAttraction = placesService.places.first {
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
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        // Placeholder when no photo
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 200)
                                            .overlay(
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 50))
                                            )
                                    }
                                    
                                    // Attraction Details
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(topAttraction.displayName.text)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        
                                        Text(topAttraction.formattedAddress)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
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
                                    Text("AI Tour Guide")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
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
                        }
                    } else {
                        Text("Getting location...")
                            .font(.title2)
                    }
                }
                .padding()
            }
            .navigationTitle("PathVoice")
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
        .onAppear {
            startAutoUpdateTimer()
        }
        .onDisappear {
            stopAutoUpdateTimer()
        }
    }
    
    private func startAutoUpdateTimer() {
        // Start timer to update every minute
        autoUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            if let loc = locationManager.location {
                placesService.fetchNearbyTouristAttractions(coordinate: loc, radius: 400.0)
            }
        }
    }
    
    private func stopAutoUpdateTimer() {
        autoUpdateTimer?.invalidate()
        autoUpdateTimer = nil
    }
}

#Preview {
    ContentView()
}
