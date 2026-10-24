import MapKit
import SwiftUI

struct ParkingReadyMapView: View {
    @Environment(LocationService.self) private var locationService
    var body: some View {
        SwiftUI.Group {
            if let coordinate = locationService.location?.coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(center: coordinate, span: .init(latitudeDelta: 0.008, longitudeDelta: 0.008)))) { UserAnnotation() }
                    .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                    .safeAreaInset(edge: .bottom) { spotCaption }
                    .accessibilityLabel("Map around your current location")
            } else {
                ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "parkingsign")
                        .font(.system(size: 76, weight: .ultraLight))
                        .foregroundStyle(DesignSystem.warmAccent)
                    Text("A moment for you.\nA spot remembered.")
                        .font(.system(.title, design: .serif)).multilineTextAlignment(.center)
                    Text("Start a timer to save your location and keep your parking details close.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).frame(maxWidth: 280)
                }
                .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                .background(DesignSystem.cardBackground)
            }
        }
    }

    private var spotCaption: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR NEXT STOP").font(.caption2.weight(.semibold)).tracking(2).foregroundStyle(DesignSystem.warmAccent)
            Text(locationService.locationName).font(.system(.title2, design: .serif))
            Text("Saved with your timer. Ready when you return.").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(24)
        .background(DesignSystem.cardBackground)
    }

}
