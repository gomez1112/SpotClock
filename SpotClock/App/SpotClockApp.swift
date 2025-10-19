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
    
    init() {
        let timerService = TimerService()
        let locationService = LocationService()
        let subscriptionService = SubscriptionService()
        
        self.timerService = timerService
        self.locationService = locationService
        self.subscriptionService = subscriptionService
        
        AppDependencyManager.shared.add(dependency: timerService)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(timerService)
                .environment(subscriptionService)
                .environment(locationService)
        }
        .modelContainer(container)
    }
}
