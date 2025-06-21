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

    var body: some View {
        NavigationView {
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
                        placesService.fetchNearbyTouristAttractions(coordinate: loc)
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
                    
                    if !placesService.places.isEmpty {
                        List(placesService.places) { place in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(place.displayName.text)
                                    .font(.headline)
                                Text(place.formattedAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let primaryType = place.primaryType {
                                    Text(primaryType)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                } else {
                    Text("Getting location...")
                        .font(.title2)
                }
            }
            .padding()
            .navigationTitle("Nearby Attractions")
        }
    }
}

#Preview {
    ContentView()
}
