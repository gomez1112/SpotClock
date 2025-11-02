//
//  DirectionsMapView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/20/25.
//

import MapKit
import SwiftUI
import OSLog

struct DirectionsMapView: View {
    let carLocation: CLLocationCoordinate2D
    let carAddress: String
    
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationService.self) private var locationService
    
    @State private var route: MKRoute?
    @State private var position: MapCameraPosition = .automatic
    @State private var isLoadingRoute = true
    @State private var showRouteError = false
    @State private var routeErrorMessage = ""
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SpotClock", category: "Directions")
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map with route
                Map(position: $position) {
                    // User location marker
                    if let userLocation = locationService.location?.coordinate {
                        Marker("You", systemImage: "person.fill", coordinate: userLocation)
                            .tint(.blue)
                    }
                    
                    // Car location marker
                    Marker(carAddress, systemImage: "car.fill", coordinate: carLocation)
                        .tint(.red)
                    
                    // Route polyline
                    if let route {
                        MapPolyline(route.polyline)
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                
                // Route info overlay
                VStack {
                    Spacer()
                    
                    if isLoadingRoute {
                        routeLoadingCard
                    } else if let route {
                        routeInfoCard(route: route)
                    }
                }
                .padding()
            }
            .navigationTitle("Directions to Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        openInMaps()
                    } label: {
                        Label("Open in Maps", systemImage: "map.fill")
                    }
                }
            }
            .task {
                await fetchRoute()
            }
            .alert("Couldn’t Load Directions", isPresented: $showRouteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(routeErrorMessage)
            }
        }
    }
    
    // MARK: - Route Loading Card
    private var routeLoadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Calculating route...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    // MARK: - Route Info Card
    private func routeInfoCard(route: MKRoute) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Distance
                VStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text(formatDistance(route.distance))
                        .font(.headline)
                    Text("Distance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                // Time
                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text(formatDuration(route.expectedTravelTime))
                        .font(.headline)
                    Text("Walking Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Open in Maps button
            Button {
                openInMaps()
            } label: {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Open in Apple Maps")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .foregroundStyle(.white)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
    }
    
    // MARK: - Fetch Route
    private func fetchRoute() async {
        guard let userLocation = locationService.location?.coordinate else {
            isLoadingRoute = false
            logger.warning("User location unavailable; cannot calculate route.")
            routeErrorMessage = "Your current location isn’t available. Please enable Location Services and try again."
            showRouteError = true
            return
        }
        
        let request = MKDirections.Request()
        
        if #available(iOS 26.0, *) {
            let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let carCLLocation = CLLocation(latitude: carLocation.latitude, longitude: carLocation.longitude)
            request.source = MKMapItem(location: userCLLocation, address: nil)
            request.destination = MKMapItem(location: carCLLocation, address: nil)
        } else {
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: carLocation))
        }
        
        request.transportType = .walking
        
        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            
            if let firstRoute = response.routes.first {
                self.route = firstRoute
                
                // Set camera to show entire route
                let rect = firstRoute.polyline.boundingMapRect
                position = .rect(rect.insetBy(
                    dx: -rect.size.width * 0.2,
                    dy: -rect.size.height * 0.2
                ))
            }
            
            isLoadingRoute = false
        } catch {
            logger.error("Failed to calculate route: \(error.localizedDescription, privacy: .public)")
            isLoadingRoute = false
            routeErrorMessage = "We couldn’t calculate a walking route to your car. Please try again in a moment. (\(error.localizedDescription))"
            showRouteError = true
        }
    }
    
    // MARK: - Open in Maps
    private func openInMaps() {
            let carCLLocation = CLLocation(latitude: carLocation.latitude, longitude: carLocation.longitude)
            let carMapItem = MKMapItem(location: carCLLocation, address: nil)
            carMapItem.name = carAddress
            carMapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
            ])
        
    }
    
    // MARK: - Formatting Helpers
    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return "\(Int(meters)) m"
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

#Preview {
    DirectionsMapView(
        carLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        carAddress: "Downtown Plaza Garage"
    )
    .environment(LocationService())
}

