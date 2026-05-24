//
//  ParkingHeatmapView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import MapKit
import SwiftUI

struct ParkingHeatmapView: View {
    let locations: [LocationData]
    @State private var position: MapCameraPosition
    
    init(locations: [LocationData]) {
        self.locations = locations
        _position = State(initialValue: Self.cameraPosition(for: locations))
    }
    
    var body: some View {
        Map(position: $position) {
            ForEach(locations) { location in
                Annotation(
                    location.name,
                    coordinate: location.coordinate
                ) {
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(colorForFrequency(location.visits).opacity(0.3))
                            .frame(width: CGFloat(30 + min(location.visits * 6, 60)))
                            .blur(radius: 5)
                        
                        // Main circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        colorForFrequency(location.visits),
                                        colorForFrequency(location.visits).opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: CGFloat(25 + min(location.visits * 5, 50)))
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.5), lineWidth: 2)
                            )
                        
                        // Count badge
                        Circle()
                            .fill(.white)
                            .frame(width: 24)
                        
                        Text("\(location.visits)")
                            .font(.caption2.bold())
                            .foregroundStyle(colorForFrequency(location.visits))
                    }
                    .shadow(color: colorForFrequency(location.visits).opacity(0.4), radius: 10, y: 5)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .onChange(of: locationChangeToken, initial: true) { _, _ in
            position = Self.cameraPosition(for: locations)
        }
    }
    
    private static func cameraPosition(for locations: [LocationData]) -> MapCameraPosition {
        guard !locations.isEmpty else {
            return .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
        
        let avgLat = locations.map(\.coordinate.latitude).reduce(0, +) / Double(locations.count)
        let avgLon = locations.map(\.coordinate.longitude).reduce(0, +) / Double(locations.count)
        
        return .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )
    }
    
    private func colorForFrequency(_ visits: Int) -> Color {
        switch visits {
            case 1...3:
                return .cyan
            case 4...7:
                return .blue
            case 8...15:
                return .green
            case 16...25:
                return .yellow
            case 26...50:
                return .orange
            default:
                return .red
        }
    }

    private var locationChangeToken: String {
        locations
            .map { location in
                "\(location.id.uuidString)-\(location.coordinate.latitude)-\(location.coordinate.longitude)-\(location.visits)"
            }
            .joined(separator: "|")
    }
}

#Preview {
    ParkingHeatmapView(locations: [LocationData(name: "New York", visits: 2, coordinate: CLLocationCoordinate2D(latitude: 23.2323, longitude: 23.44543), averageDuration: 60)])
}
