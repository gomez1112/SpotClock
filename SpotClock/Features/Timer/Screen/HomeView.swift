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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                if timerManager.isRunning, let session = timerManager.activeSession {
                    ActiveTimerView(session: session)
                } else {
                    idleView
                }
            }
            .navigationTitle("SpotClock")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showNewTimer) {
                NewTimerView()
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
        }
    }

    private var idleView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.brandTeal.opacity(pulseAnimation ? 0.18 : 0.08))
                            .frame(width: 176, height: 176)
                            .scaleEffect(reduceMotion ? 1 : (pulseAnimation ? 1.04 : 0.96))
                            .animation(
                                reduceMotion
                                ? .default
                                : .smooth(duration: 1.8).repeatForever(autoreverses: true),
                                value: pulseAnimation
                            )

                        Image(systemName: "parkingsign.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 92, weight: .semibold))
                            .foregroundStyle(DesignSystem.primaryGradient)
                    }
                    .onAppear { pulseAnimation = true }

                    VStack(spacing: 10) {
                        Text("Ready to Park")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)

                        Text("Start a timer, save your spot, and get back before time runs out.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if !subscriptionManager.hasProAccess {
                        Label("\(subscriptionManager.sessionsRemaining) free timers remaining this month", systemImage: "timer.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(DesignSystem.elevatedCardBackground, in: .capsule)
                            .overlay(
                                Capsule()
                                    .strokeBorder(DesignSystem.cardStroke(), lineWidth: 1)
                            )
                            .accessibilityLabel("\(subscriptionManager.sessionsRemaining) free parking timers remaining this month")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .appCard(fill: DesignSystem.elevatedCardBackground)

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
                        Label("Start Parking Timer", systemImage: "play.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .tint(DesignSystem.brandBlue)
                    .buttonSizing(.flexible)
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(subscriptionManager.canStartSession ? "Start parking timer" : "Upgrade to start more parking timers")
                    .accessibilityHint(subscriptionManager.canStartSession ? "Opens timer setup." : "Opens the subscription screen.")

                    if !subscriptionManager.hasProAccess && subscriptionManager.sessionsRemaining == 0 {
                        Button {
                            showSubscription = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(DesignSystem.warmAccent)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upgrade to Pro")
                                        .font(.headline)
                                    Text("Get unlimited parking timers")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .appCard(fill: DesignSystem.elevatedCardBackground, cornerRadius: 18)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens subscription options.")
                    }
                }
            }
            .padding(DesignSystem.screenPadding)
            .appContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

#Preview(traits: .previewData) {
    HomeView()
        .environment(LocationService())
        .environment(SubscriptionService())
        .environment(TimerService(container: ModelContainerFactory.createPreviewContainer))
}
