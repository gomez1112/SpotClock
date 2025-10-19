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

    /// Fetch a walking ETA (seconds) from `user` to `car` using MapKit's async directions.
    /// Throttled to avoid spamming the API if called frequently.
    func etaSeconds(
        from user: CLLocationCoordinate2D,
        to car: CLLocationCoordinate2D
    ) async -> TimeInterval? {
        let now = Date()
        if now.timeIntervalSince(lastFetch) < throttleSeconds, lastETA > 0 {
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
                return lastETA
            }
            return lastETA > 0 ? lastETA : nil
        } catch {
            // Network hiccups: fall back to last good ETA if available
            return lastETA > 0 ? lastETA : nil
        }
    }
}
