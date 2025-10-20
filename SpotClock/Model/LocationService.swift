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
    
    // ✅ FIXED: Add a continuation property to bridge the delegate callback with an async function.
    private var locationContinuation: CheckedContinuation<CLLocation?, Error>?
    
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
        
        if manager.accuracyAuthorization == .reducedAccuracy {
            manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "ParkingLocation")
        }
    }
    
    // ✅ FIXED: This new helper function reliably awaits a single location update.
    private func awaitSingleLocationUpdate() async throws -> CLLocation? {
        try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
            
            // Add a timeout to prevent waiting forever.
            Task {
                try await Task.sleep(for: .seconds(10))
                self.locationContinuation?.resume(throwing: LocationError.timeout)
                self.locationContinuation = nil
            }
        }
    }
    
    // ✅ FIXED: Replaced unreliable Task.sleep with the robust `awaitSingleLocationUpdate` function.
    func ensureLocationName() async -> String {
        if locationName != "Current Location", locationName != "Finding Location..." { return locationName }
        
        do {
            self.locationName = "Finding Location..."
            if let newLocation = try await awaitSingleLocationUpdate() {
                self.location = newLocation
                let name = await reverseGeocode(newLocation)
                self.locationName = name
                return name
            }
        } catch {
            self.errorMessage = "Could not get location: \(error.localizedDescription)"
            self.locationName = "Current Location" // Reset on failure
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
                        if let name  = item.name,                !name.isEmpty  { return name  }
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
                    var addressParts: [String] = []
                    if let name = p.name { addressParts.append(name) }
                    if let locality = p.locality { addressParts.append(locality) }
                    if !addressParts.isEmpty { return addressParts.joined(separator: ", ") }
                }
            } catch {
                self.errorMessage = "Reverse geocoding (CLGeocoder) failed: \(error.localizedDescription)"
            }
        }
        return "Unnamed Location"
    }
}

enum LocationError: Error {
    case timeout
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in
            // ✅ FIXED: Resume the continuation with the new location and clear it.
            self.locationContinuation?.resume(returning: last)
            self.locationContinuation = nil
            
            // This part handles continuous background updates if needed elsewhere.
            self.location = last
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            // ✅ FIXED: If the manager fails, throw the error to the awaiting function.
            self.locationContinuation?.resume(throwing: error)
            self.locationContinuation = nil
            self.errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            }
        }
    }
}


