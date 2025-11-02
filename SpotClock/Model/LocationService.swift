//
//  LocationManager.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//


import Foundation
import CoreLocation
@preconcurrency import MapKit

@Observable
final class LocationService: NSObject {
    private let manager = CLLocationManager()
    
    // ✅ FIXED: Add a continuation property to bridge the delegate callback with an async function.
    private var locationContinuation: CheckedContinuation<CLLocation?, Error>?
    private var hasRequestedFullAccuracy = false
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationName: String = "Current Location"
    var errorMessage: String?
    
    // ✅ NEW: Track if we're actively updating location
    private var isUpdatingLocation = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .other
        manager.distanceFilter = kCLDistanceFilterNone
        manager.allowsBackgroundLocationUpdates = false
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        
        if manager.accuracyAuthorization == .reducedAccuracy && !hasRequestedFullAccuracy {
            manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "ParkingLocation")
            hasRequestedFullAccuracy = true
        }
    }
    
    // ✅ NEW: Start continuous location updates (for maps)
    func startUpdatingLocation() {
        guard !isUpdatingLocation else { return }
        isUpdatingLocation = true
        manager.startUpdatingLocation()
    }
    
    // ✅ NEW: Stop continuous location updates
    func stopUpdatingLocation() {
        guard isUpdatingLocation else { return }
        isUpdatingLocation = false
        manager.stopUpdatingLocation()
    }
    
    func ensureLocationName() async -> String {
        // Always fetch fresh location for accurate parking location tracking
        
        do {
            self.locationName = "Finding Location..."
            if let newLocation = try await awaitSingleLocationUpdate() {
                self.location = newLocation
                let name = await reverseGeocode(newLocation)
                self.locationName = name
                return name
            }
        } catch is LocationError {
            self.errorMessage = "Location request timed out"
            self.locationName = "Current Location"
        } catch {
            self.errorMessage = "Could not get location: \(error.localizedDescription)"
            self.locationName = "Current Location"
        }
        
        return locationName
    }
    
    private func awaitSingleLocationUpdate() async throws -> CLLocation? {
        
        guard locationContinuation == nil else {
            throw LocationError.requestInProgress
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
            
            // ✅ FIXED: Capture continuation weakly to avoid double-resume
            Task { [weak self] in
                try await Task.sleep(for: .seconds(10))
                
                // ✅ FIXED: Only resume if continuation still exists
                if let cont = self?.locationContinuation {
                    self?.locationContinuation = nil
                    cont.resume(throwing: LocationError.timeout)
                }
            }
        }
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
    case requestInProgress
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in
            // Update the current location for continuous tracking
            self.location = last
            
            // ✅ FIXED: Resume the continuation with the new location and clear it (for single updates).
            self.locationContinuation?.resume(returning: last)
            self.locationContinuation = nil
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
                if self.locationContinuation == nil && !self.isUpdatingLocation {
                    self.manager.requestLocation()
                }
            }
        }
    }
}


