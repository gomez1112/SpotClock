//
//  ContentView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(TimerService.self) var timerManager: TimerService
    @State private var showOnboarding: Bool
    private enum Tabs: Hashable { case insights, timer, history, settings }
    @State private var selectedTab: Tabs = .timer
    
    init(skipsOnboarding: Bool = false) {
        showOnboarding = !skipsOnboarding && !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }

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
            Tab("Insights", systemImage: "chart.xyaxis.line", value: Tabs.insights) {
                InsightsView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: Tabs.history) {
                HistoryView()
            }

            Tab("Settings", systemImage: "gear", value: Tabs.settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(DesignSystem.brandBlue)
    }
}
