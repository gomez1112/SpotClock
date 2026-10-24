import AppIntents
import SwiftData
import SwiftUI

@main
struct SpotClockApp: App {
    private let container: ModelContainer
    private let subscriptionService: SubscriptionService
    private let timerService: TimerService
    private let locationService: LocationService
    private let walkETAService: WalkETAService
    private let isMarketingCapture: Bool

    init() {
        #if DEBUG
        let captureRequested = ProcessInfo.processInfo.arguments.contains("--marketing-capture")
        isMarketingCapture = captureRequested
        if captureRequested {
            do {
                container = try ModelContainer(for: ParkingSession.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
            } catch {
                // The debug-only capture launch must never fall back to a customer's store.
                fatalError("Could not initialize the isolated capture store: \(error.localizedDescription)")
            }
        } else {
            container = ModelContainerFactory.createSharedContainer
        }
        #else
        let captureRequested = false
        isMarketingCapture = false
        container = ModelContainerFactory.createSharedContainer
        #endif
        let timer = TimerService(container: container, restoresSession: !captureRequested)
        timer.isCaptureSession = captureRequested
        timerService = timer
        let location = LocationService()
        location.isCaptureSession = captureRequested
        locationService = location
        subscriptionService = SubscriptionService(persistsUsage: !captureRequested)
        walkETAService = WalkETAService()
        AppDependencyManager.shared.add(dependency: timer)
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if isMarketingCapture {
                MarketingCaptureStudioView()
            } else {
                appContent
            }
            #else
            appContent
            #endif
        }
        .modelContainer(container)
    }

    private var appContent: some View {
        ContentView()
            .environment(timerService)
            .environment(subscriptionService)
            .environment(locationService)
            .environment(walkETAService)
    }
}
