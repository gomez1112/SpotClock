//
//  LocationData.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import MapKit

struct LocationData: Identifiable {
    let id = UUID()
    let name: String
    let visits: Int
    let coordinate: CLLocationCoordinate2D
    let averageDuration: TimeInterval
}
