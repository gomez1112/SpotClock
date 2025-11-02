//
//  WalkETAService.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//


import Foundation
import MapKit
import CoreLocation

@Observable
final class WalkETAService {
    private var lastETA: TimeInterval = 0
    private let throttleSeconds: TimeInterval = 30
    private var lastFetch: Date = .distantPast

    private var lastFromCoordinate: CLLocationCoordinate2D?
    private var lastToCoordinate: CLLocationCoordinate2D?
    
    /// Fetch a walking ETA (seconds) from `user` to `car` using MapKit's async directions.
    /// Throttled to avoid spamming the API if called frequently.
    func etaSeconds(
        from user: CLLocationCoordinate2D,
        to car: CLLocationCoordinate2D
    ) async -> TimeInterval? {
        let now = Date()
        
        let coordinatesChanged = hasLocationChanged(from: lastFromCoordinate, to: user, threshold: 50) || hasLocationChanged(from: lastToCoordinate, to: car, threshold: 50)
        if now.timeIntervalSince(lastFetch) < throttleSeconds, lastETA > 0, !coordinatesChanged {
            return lastETA
        }

        let req = MKDirections.Request()
        let userLocation = CLLocation(latitude: user.latitude, longitude: user.longitude)
        let carLocation = CLLocation(latitude: car.latitude, longitude: car.longitude)
        if #available(iOS 26.0, *) {
            req.source = MKMapItem(location: userLocation, address: nil)
            req.destination = MKMapItem(location: carLocation, address: nil)
        } else {
            req.source = MKMapItem(placemark: MKPlacemark(coordinate: user))
            req.destination = MKMapItem(placemark: MKPlacemark(coordinate: car))
        }
        req.transportType = .walking
        req.requestsAlternateRoutes = true

        do {
            let response = try await MKDirections(request: req).calculate()
            if let best = response.routes.min(by: { $0.expectedTravelTime < $1.expectedTravelTime }) {
                lastETA = best.expectedTravelTime
                lastFetch = now
                lastFromCoordinate = user
                lastToCoordinate = car
                return lastETA
            }
            return lastETA > 0 ? lastETA : nil
        } catch {
            // Network hiccups: fall back to last good ETA if available
            return lastETA > 0 ? lastETA : nil
        }
    }
    private func hasLocationChanged(
        from oldCoord: CLLocationCoordinate2D?,
        to newCoord: CLLocationCoordinate2D,
        threshold: Double
    ) -> Bool {
        guard let oldCoord else { return true }
        
        let oldLocation = CLLocation(latitude: oldCoord.latitude, longitude: oldCoord.longitude)
        let newLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
        
        return oldLocation.distance(from: newLocation) > threshold
    }
}
