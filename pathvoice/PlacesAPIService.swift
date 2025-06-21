//
//  PlacesAPIService.swift
//  pathvoice
//
//  Created by Ayush Pai on 6/21/25.
//

import Foundation
import CoreLocation

struct PlacesResponse: Codable {
    let places: [Place]
}

struct Place: Codable, Identifiable {
    let id = UUID()
    let displayName: DisplayName
    let formattedAddress: String
    let primaryType: String?
    let types: [String]
    let location: Location
    let photos: [PlacePhoto]?
    
    enum CodingKeys: String, CodingKey {
        case displayName
        case formattedAddress
        case primaryType
        case types
        case location
        case photos
    }
}

struct DisplayName: Codable {
    let text: String
    let languageCode: String
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
}

struct PlacePhoto: Codable {
    let name: String
    let widthPx: Int
    let heightPx: Int
    let authorAttributions: [AuthorAttribution]
}

struct AuthorAttribution: Codable {
    let displayName: String
    let uri: String
    let photoUri: String
}

class PlacesAPIService: ObservableObject {
    private let apiKey = "AIzaSyC1olvnH7yx1PghTjGQIgToOZ3Qogme-nQ"
    private let baseURL = "https://places.googleapis.com/v1/places:searchNearby"
    
    @Published var places: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchNearbyTouristAttractions(coordinate: CLLocationCoordinate2D, radius: Double = 200.0) {
        isLoading = true
        errorMessage = nil
        
        let requestBody: [String: Any] = [
            "includedTypes": ["tourist_attraction"],
            "maxResultCount": 10,
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": coordinate.latitude,
                        "longitude": coordinate.longitude
                    ],
                    "radius": radius
                ]
            ]
        ]
        
        guard let url = URL(string: baseURL) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.displayName,places.formattedAddress,places.primaryType,places.types,places.location,places.photos", forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            errorMessage = "Failed to serialize request body: \(error.localizedDescription)"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let placesResponse = try JSONDecoder().decode(PlacesResponse.self, from: data)
                    self?.places = placesResponse.places
                } catch {
                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
            }
        }.resume()
    }

    func getPhotoURL(for photo: PlacePhoto, maxWidth: Int = 200) -> URL? {
        let baseURL = "https://places.googleapis.com/v1/\(photo.name)/media"
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "maxWidthPx", value: "\(maxWidth)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        return components?.url
    }
} 
