//
//  LocationManager.swift
//  pathvoice
//
//  Created by Ayush Pai on 6/21/25.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var location: CLLocationCoordinate2D?
    @Published var locationName: String = "Getting location..."

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last?.coordinate
        
        // Reverse geocode to get location name
        if let location = locations.last {
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Geocoding error: \(error)")
                        self?.locationName = "Unknown location"
                        return
                    }
                    
                    if let placemark = placemarks?.first {
                        var locationParts: [String] = []
                        
                        if let locality = placemark.locality {
                            locationParts.append(locality)
                        }
                        if let administrativeArea = placemark.administrativeArea {
                            locationParts.append(administrativeArea)
                        }
                        if let country = placemark.country {
                            locationParts.append(country)
                        }
                        
                        self?.locationName = locationParts.isEmpty ? "Unknown location" : locationParts.joined(separator: ", ")
                    } else {
                        self?.locationName = "Unknown location"
                    }
                }
            }
        }
    }
}
