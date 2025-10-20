//
//  SpotClockApp.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import AppIntents
import SwiftData
import SwiftUI

@main
struct SpotClockApp: App {
    private let container = ModelContainerFactory.createSharedContainer
    private let subscriptionService: SubscriptionService
    private let timerService: TimerService
    private let locationService: LocationService
    private let walkETAService: WalkETAService
    
    init() {
        let timerService = TimerService(container: container)
        let locationService = LocationService()
        let subscriptionService = SubscriptionService()
        let walkETAService = WalkETAService()
        
        self.timerService = timerService
        self.locationService = locationService
        self.subscriptionService = subscriptionService
        self.walkETAService = walkETAService
        
        AppDependencyManager.shared.add(dependency: timerService)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(timerService)
                .environment(subscriptionService)
                .environment(locationService)
                .environment(walkETAService)
        }
        .modelContainer(container)
    }
}
