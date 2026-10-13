//
//  DirectionsMapView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/20/25.
//


import MapKit
import SwiftUI
import OSLog

@available(iOS 27.1, *)
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
            ArrangementView {
                DirectionsSummaryPanel {
                    if isLoadingRoute {
                        routeLoadingCard
                    } else if let route {
                        routeInfoCard(route: route)
                    } else {
                        Text(routeErrorMessage)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .appCard(fill: DesignSystem.elevatedCardBackground)
                    }
                }
                .overlayArrangementEdge(.bottom)
            } secondary: {
                Map(position: $position) {
                    UserAnnotation()
                    Marker(carAddress, systemImage: "car.fill", coordinate: carLocation)
                        .tint(.red)
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
            }
            .arrangementViewStyle(.overlay)
            .background { AppBackground() }
            .navigationTitle("Directions to Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") {
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
                // ✅ FIXED: Request fresh location before calculating route
                await refreshLocationAndRoute()
            }
            .alert("Couldn't Load Directions", isPresented: $showRouteError) {
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
            Text("Calculating route…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .appCard(fill: DesignSystem.elevatedCardBackground, cornerRadius: 16)
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
        .appCard(fill: DesignSystem.elevatedCardBackground, cornerRadius: 20)
    }
    
    // MARK: - ✅ NEW: Refresh location before fetching route
    private func refreshLocationAndRoute() async {
        // Request a fresh location update
        _ = await locationService.ensureLocationName()
        
        // Small delay to ensure location is updated
        try? await Task.sleep(for: .milliseconds(500))
        
        // Now fetch the route with current location
        await fetchRoute()
    }
    
    // MARK: - Fetch Route
    private func fetchRoute() async {
        guard let userLocation = locationService.location?.coordinate else {
            isLoadingRoute = false
            logger.warning("User location unavailable; cannot calculate route.")
            routeErrorMessage = "Your current location isn't available. Please enable Location Services and try again."
            showRouteError = true
            return
        }
        
        let request = MKDirections.Request()
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let carCLLocation = CLLocation(latitude: carLocation.latitude, longitude: carLocation.longitude)
        request.source = MKMapItem(location: userCLLocation, address: nil)
        request.destination = MKMapItem(location: carCLLocation, address: nil)

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
            routeErrorMessage = "We couldn't calculate a walking route to your car. Please try again in a moment. (\(error.localizedDescription))"
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
            let kilometers = (meters / 1000).formatted(.number.precision(.fractionLength(1)))
            return "\(kilometers) km"
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

// The panel stays over the map when flat and moves below/beside it when folded.
// Its own scroll view keeps route actions reachable at accessibility text sizes.
@available(iOS 27.1, *)
private struct DirectionsSummaryPanel<Content: View>: View {
    @Environment(\.overlayArrangementZIndex) private var overlayZIndex
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.bottom, for: .alignment)
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxWidth: DesignSystem.maxRouteSummaryWidth)
            // Measure this arrangement region, which can be only half the display.
            .frame(height: geometry.size.height * (overlayZIndex == 1 ? DesignSystem.overlaidRouteSummaryHeightFraction : 1))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .padding(DesignSystem.screenPadding)
    }
}
