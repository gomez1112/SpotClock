#if DEBUG
import CoreLocation
import SwiftData
import SwiftUI

/// An isolated, in-memory capture environment. It never restores a customer's
/// timer, writes parking history to disk, or requests/schedules a sample alarm.
struct MarketingCaptureStudioView: View {
    @State private var capture = MarketingCaptureSession()

    var body: some View {
        ContentView(skipsOnboarding: true)
            .modelContainer(capture.container)
            .environment(capture.timer)
            .environment(capture.subscription)
            .environment(capture.location)
            .environment(capture.walkETA)
            .environment(\.isMarketingCapture, true)
    }
}

extension EnvironmentValues {
    @Entry var isMarketingCapture = false
}

@MainActor
@Observable
private final class MarketingCaptureSession {
    let container: ModelContainer
    let timer: TimerService
    let subscription = SubscriptionService(persistsUsage: false)
    let location = LocationService()
    let walkETA = WalkETAService()

    init() {
        do {
            container = try ModelContainer(
                for: ParkingSession.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            )
        } catch {
            // Only reachable in the explicitly opened debug capture studio.
            fatalError("Could not create isolated screenshot data: \(error.localizedDescription)")
        }
        timer = TimerService(container: container, restoresSession: false)
        timer.isCaptureSession = true
        location.isCaptureSession = true
        location.locationName = "Hayes Valley"
        location.location = CLLocation(latitude: 37.7801, longitude: -122.4246)
        location.authorizationStatus = .authorizedWhenInUse
        let now = Date()
        let locations: [(String, Double, Double, String)] = [
            ("Hayes Valley", 37.7769, -122.4241, "Zone 4B · near the coffee shop"),
            ("Marina District", 37.8002, -122.4368, "Afternoon by the water"),
            ("North Beach", 37.8004, -122.4091, "Dinner with friends"),
            ("Golden Gate Park", 37.7694, -122.4862, "A little time outside")
        ]
        for index in 0..<28 {
            let spot = locations[index % locations.count]
            let start = now.addingTimeInterval(-Double(index + 1) * 19 * 3600)
            let duration = Double([45, 90, 60, 120, 75, 105, 30][index % 7]) * 60
            container.mainContext.insert(ParkingSession(
                startTime: start, endTime: start.addingTimeInterval(duration), duration: duration,
                location: spot.0, latitude: spot.1, longitude: spot.2, notes: spot.3,
                wasExtended: index.isMultiple(of: 6)
            ))
        }
        let active = ParkingSession(
            startTime: now.addingTimeInterval(-3600),
            endTime: now.addingTimeInterval(44 * 60 + 7), duration: 7200,
            location: "Hayes Valley", latitude: 37.7769, longitude: -122.4241,
            notes: "Zone 4B · near the coffee shop"
        )
        timer.activeSession = active
        timer.timeRemaining = 44 * 60 + 7
        timer.isRunning = true
    }
}
#endif
