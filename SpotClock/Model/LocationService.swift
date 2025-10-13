//
//  LocationManager.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

// LocationManager.swift
import Foundation
import CoreLocation
@preconcurrency import MapKit

@Observable
final class LocationService: NSObject {
    private let manager = CLLocationManager()
    
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationName: String = "Current Location"
    var errorMessage: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .other
        manager.distanceFilter = kCLDistanceFilterNone
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        
        // Ask for precise accuracy if user granted Reduced Accuracy
        if manager.accuracyAuthorization == .reducedAccuracy {
            // Add “NSLocationTemporaryUsageDescriptionDictionary” → { "ParkingLocation" : "…" } to Info.plist
            manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "ParkingLocation")
        }
    }
    
    func getCurrentLocation() {
        manager.requestLocation()
    }
    
    // PUBLIC: make sure we have a human-readable name (used by UI before saving a session)
    func ensureLocationName() async -> String {
        // If we already have a readable address, return it
        if locationName != "Current Location" { return locationName }
        
        // If we already have coordinates, try reverse-geocoding immediately
        if let loc = location {
            let name = await reverseGeocode(loc)
            self.locationName = name
            return name
        }
        
        // Otherwise trigger a one-shot and give it a moment
        manager.requestLocation()
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s gentle wait without withChecked*
        if let loc = self.location {
            let name = await reverseGeocode(loc)
            self.locationName = name
            return name
        }
        return locationName
    }
    
    // Reverse-geocode with iOS-18 MapKit first, then clean iOS-17 fallback.
    func reverseGeocode(_ location: CLLocation) async -> String {
        // iOS 18 path
        if #available(iOS 18.0, *) {
            if let request = MKReverseGeocodingRequest(location: location) {
                do {
                    if let item = try await request.mapItems.first {
                        if let short = item.address?.shortAddress, !short.isEmpty { return short }
                        if let full  = item.address?.fullAddress,  !full.isEmpty  { return full  }
                        if let name  = item.name,                 !name.isEmpty  { return name  }
                        // last-ditch: coordinates
                        return String(format: "%.5f, %.5f",
                                      item.location.coordinate.latitude,
                                      item.location.coordinate.longitude)
                    }
                } catch {
                    self.errorMessage = "Reverse geocoding (MapKit) failed: \(error.localizedDescription)"
                }
            }
        } else {
            // iOS 17 (or fallback) using CLGeocoder (async/await)
            do {
                let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
                if let p = placemarks.first {
                    // Build a compact address
                    let parts = [
                        p.name,                // POI / street + number when available
                        p.locality,            // city
                        p.administrativeArea,  // state
                        p.postalCode           // zip
                    ].compactMap { $0 }.filter { !$0.isEmpty }
                    if !parts.isEmpty { return parts.joined(separator: ", ") }
                }
            } catch {
                self.errorMessage = "Reverse geocoding (CLGeocoder) failed: \(error.localizedDescription)"
            }
        }
        
        
        
        return "Current Location"
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let coord = last.coordinate
        Task { @MainActor in
            let current = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            self.location = current
            // Kick off a background refresh of the readable name
            self.locationName = await self.reverseGeocode(current)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.errorMessage = "Location error: \(error.localizedDescription)" }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.getCurrentLocation()
            }
        }
    }
}


