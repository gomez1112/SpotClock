//
//  MapView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import MapKit
import SwiftUI

struct MapView: View {
    let session: ParkingSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var position: MapCameraPosition
    
    init(session: ParkingSession) {
        self.session = session
        let coordinate = CLLocationCoordinate2D(
            latitude: session.latitude,
            longitude: session.longitude
        )
        self._position = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }
    
    var body: some View {
        NavigationStack {
            Map(position: $position) {
                Marker(session.location, systemImage: "car.fill", coordinate: CLLocationCoordinate2D(
                    latitude: session.latitude,
                    longitude: session.longitude
                ))
                .tint(.blue)
            }
            .navigationTitle("Parking Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MapView(session: ParkingSession(endTime: Date(), duration: 2000000))
}
