//
//  LocationService.swift
//  VoiceNotesApp
//
//  Manages location tracking and reverse geocoding
//

import CoreLocation
import Combine

/// Location data captured for a recording
struct LocationData {
    let latitude: Double
    let longitude: Double
    let placeName: String?
    let address: String?
}

/// Service responsible for location tracking and geocoding
class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var locationPermissionGranted = false
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkPermission()
    }
    
    /// Checks current location permission status
    func checkPermission() {
        let status = locationManager.authorizationStatus
        locationPermissionGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    
    /// Requests location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Captures current location with place name
    func captureLocation() async -> LocationData? {
        // Request permission if not granted
        if !locationPermissionGranted {
            requestPermission()
            // Wait a bit for permission response
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        // If still not granted, return nil
        guard locationPermissionGranted else {
            return nil
        }
        
        // Request location
        locationManager.requestLocation()
        
        // Wait for location update (with timeout)
        let location = await waitForLocation(timeout: 5.0)
        
        guard let location = location else {
            return nil
        }
        
        // Reverse geocode
        let placeInfo = await reverseGeocode(location: location)
        
        return LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            placeName: placeInfo?.placeName,
            address: placeInfo?.address
        )
    }
    
    // MARK: - Private Methods
    
    private func waitForLocation(timeout: TimeInterval) async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            
            // Set up timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: nil)
                }
            }
            
            // Wait for location update
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: nil)
                    }
                    return
                }
                
                // Check if we already have a recent location
                if let location = self.currentLocation,
                   location.timestamp.timeIntervalSinceNow > -60 {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: location)
                    }
                }
            }
        }
    }
    
    private func reverseGeocode(location: CLLocation) async -> (placeName: String?, address: String?)? {
        return await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                guard error == nil, let placemark = placemarks?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let placeName = placemark.name ?? placemark.locality
                let address = self.formatAddress(from: placemark)
                
                continuation.resume(returning: (placeName, address))
            }
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        return components.joined(separator: ", ")
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkPermission()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

