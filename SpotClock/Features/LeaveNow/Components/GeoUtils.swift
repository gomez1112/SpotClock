//
//  GeoUtils.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//


import CoreLocation

enum GeoUtils {
    static func distanceMeters(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let a = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let b = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return a.distance(from: b)
    }

    /// Bearing from `from` to `to` in radians, measured clockwise from due north.
    static func bearingRadians(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let φ1 = from.latitude  * .pi / 180
        let φ2 = to.latitude    * .pi / 180
        let Δλ = (to.longitude - from.longitude) * .pi / 180
        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
        return atan2(y, x)
    }
}
