//
//  SpotClockApp.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import SwiftData
import SwiftUI

@main
struct SpotClockApp: App {
    @State private var timerManager = TimerManager()
    @State private var subscriptionManager = SubscriptionService()
    @State private var locationManager = LocationService()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ParkingSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(timerManager)
                .environment(subscriptionManager)
                .environment(locationManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
