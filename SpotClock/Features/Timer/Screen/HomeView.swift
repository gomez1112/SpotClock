//
//  HomeView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//
import SwiftUI
import MapKit
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerManager
    @Environment(SubscriptionService.self) private var subscriptionManager
    @Environment(LocationService.self) private var locationManager: LocationService
    @State private var showNewTimer = false
    @State private var showSubscription = false
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Enhanced background with subtle gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95),
                        Color.blue.opacity(0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if timerManager.isRunning, let session = timerManager.activeSession {
                    ActiveTimerView(session: session)
                } else {
                    idleView
                }
            }
            .navigationTitle("SpotClock")
            .sheet(isPresented: $showNewTimer) {
                NewTimerView()
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .task {
                setupExpirationHandler()
            }
        }
    }
    private func setupExpirationHandler() {
        timerManager.onSessionExpired = { [modelContext] session in
            Task { @MainActor in
                modelContext.insert(session)
                try? modelContext.save()
            }
        }
    }

    private var idleView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero icon with animated glow
            ZStack {
                // Animated glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(pulseAnimation ? 0.3 : 0.15),
                                Color.blue.opacity(0)
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                    .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                // Main icon with subtle shadow
                Image(systemName: "parkingsign.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 100, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 20, y: 10)
            }
            .onAppear { pulseAnimation = true }
            
            Spacer()
                .frame(height: 40)
            
            // Title and subtitle
            VStack(spacing: 12) {
                Text("Ready to Park")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Start a timer to never get a parking ticket again")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Session counter for free users
                if !subscriptionManager.hasProAccess {
                    HStack(spacing: 8) {
                        Image(systemName: "timer.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        Text("\(subscriptionManager.sessionsRemaining) free timers remaining this month")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    if subscriptionManager.canStartSession {
                        showNewTimer = true
                    } else {
                        showSubscription = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                        Text("Start Parking Timer")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical)
                    .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
                }
                .tint(.blue)
                .buttonSizing(.flexible)
                .buttonStyle(.borderedProminent)
                // Upgrade prompt for free users at limit
                if !subscriptionManager.hasProAccess && subscriptionManager.sessionsRemaining == 0 {
                    Button {
                        showSubscription = true
                    } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                Text("Upgrade to Pro")
                                    .font(.headline)
                            }
                            Text("Get unlimited parking timers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.5), .orange.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 50)
        }
    }
}

#Preview {
    HomeView()
        .environment(LocationService())
        .environment(SubscriptionService())
        .environment(TimerService())
}
