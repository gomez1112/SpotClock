//
//  ContentView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(TimerManager.self) var timerManager: TimerManager
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    private enum Tabs: Hashable { case timer, history, settings }
    @State private var selectedTab: Tabs = .timer
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
            } else {
                mainContent
            }
        }
    }
    
    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            Tab("Timer", systemImage: "timer", value: Tabs.timer) {
                HomeView()
            }

            Tab("History", systemImage: "clock.arrow.circlepath", value: Tabs.history) {
                HistoryView()
            }

            Tab("Settings", systemImage: "gear", value: Tabs.settings) {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
        .environment(TimerManager())
        .environment(SubscriptionService())
        .environment(LocationService())
}
