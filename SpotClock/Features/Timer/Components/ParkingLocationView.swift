import MapKit
import SwiftUI

struct ParkingLocationView: View {
    var session: ParkingSession
    var showDirections: () -> Void

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: session.latitude, longitude: session.longitude)
    }

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
        ))) {
            Annotation("Your car", coordinate: coordinate) {
                Image(systemName: "car.fill")
                    .font(.title3).foregroundStyle(.white)
                    .padding(16).background(DesignSystem.ink, in: .circle)
                    .overlay { Circle().strokeBorder(.white, lineWidth: 3) }
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .accessibilityLabel("Saved car location")
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls { MapCompass(); MapScaleView() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("RIGHT WHERE YOU LEFT IT")
                        .font(.caption2.weight(.semibold)).tracking(1.5)
                        .foregroundStyle(DesignSystem.warmAccent)
                    Text(session.location.isEmpty ? "Your parking spot" : session.location)
                        .font(.system(.title2, design: .serif))
                    if !session.notes.isEmpty {
                        Text(session.notes).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Button("Walking directions", systemImage: "figure.walk", action: showDirections)
                        .buttonStyle(.borderedProminent).buttonSizing(.flexible)
                        .tint(DesignSystem.brandIndigo)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: 240)
            .fixedSize(horizontal: false, vertical: true)
            .background(DesignSystem.cardBackground)
        }
        .accessibilityLabel("Saved parking location")
    }
}
