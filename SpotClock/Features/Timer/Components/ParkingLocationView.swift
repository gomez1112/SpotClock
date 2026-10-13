import MapKit
import SwiftUI

struct ParkingLocationView: View {
    var session: ParkingSession
    var showDirections: () -> Void

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: session.latitude, longitude: session.longitude)
    }

    var body: some View {
        VStack(spacing: 0) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))) {
                Marker("Parked Car", systemImage: "car.fill", coordinate: coordinate)
                    .tint(DesignSystem.brandBlue)
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .accessibilityLabel("Saved parking location")

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Parking Location", systemImage: "location.fill")
                        .font(.headline)
                    Text(session.location.isEmpty ? "Parked Car" : session.location)
                        .font(.body)
                    if !session.notes.isEmpty {
                        Text(session.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Button("Directions to Car", systemImage: "figure.walk", action: showDirections)
                        .buttonStyle(.borderedProminent)
                        .buttonSizing(.flexible)
                        .tint(DesignSystem.brandBlue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignSystem.screenPadding)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: .infinity)
            .background(DesignSystem.cardBackground)
        }
    }
}
