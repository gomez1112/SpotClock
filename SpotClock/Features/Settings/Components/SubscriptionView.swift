//
//  SubscriptionView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(SubscriptionService.self) var subscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false

    var body: some View {
        SubscriptionStoreView(groupID: subscriptionManager.activeSubscriptionGroupID) {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                        .padding(.top, 40)
                        .padding(.bottom, 32)
                    
                    valuePropositionSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    
                    featureComparisonSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
                .appContentWidth()
            }
            .containerBackground(for: .subscriptionStoreFullHeight) {
                DesignSystem.appBackground
                .ignoresSafeArea()
            }
        }
        .subscriptionStoreControlStyle(.automatic)
        .subscriptionStoreButtonLabel(.multiline)
        .backgroundStyle(.clear)
        .subscriptionStorePickerItemBackground(.ultraThinMaterial)
        .subscriptionStorePolicyDestination(url: URL(string: "https://apple.com/legal")!, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: URL(string: "https://apple.com/privacy")!, for: .privacyPolicy)
        .onInAppPurchaseCompletion { _, _ in
            dismiss()
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Premium badge with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(DesignSystem.warmAccent.opacity(0.16))
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Crown icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.warmAccent.opacity(0.2), DesignSystem.brandTeal.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(
                            DesignSystem.warmAccent
                        )
                }
            }
            .onAppear { isAnimating = true }
            
            // Title
            VStack(spacing: 12) {
                Text("SpotClock Pro")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                
                Text("Never worry about parking tickets again")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
    
    // MARK: - Value Proposition
    private var valuePropositionSection: some View {
        VStack(spacing: 16) {
            // Main value prop
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("One Ticket = $75+")
                            .font(.title3.bold())
                        Text("Pro Subscription = $2.99/mo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text("Avoid just one parking ticket and SpotClock Pro pays for itself for over 2 years!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .appCard(fill: DesignSystem.elevatedCardBackground, cornerRadius: 20)
        }
    }
    
    
    private func roiRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
    
    // MARK: - Feature Comparison
    private var featureComparisonSection: some View {
        VStack(spacing: 16) {
            Text("What You Get")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                featureRow(
                    icon: "infinity",
                    title: "Unlimited Timers",
                    description: "Park as many times as you want",
                    color: .blue
                )
                
                featureRow(
                    icon: "bell.badge.fill",
                    title: "Smart Notifications",
                    description: "Never miss an expiration alert",
                    color: .green
                )
                
                featureRow(
                    icon: "map.fill",
                    title: "Location Saving",
                    description: "Always find your parked car",
                    color: .teal
                )
                
                featureRow(
                    icon: "clock.arrow.circlepath",
                    title: "Parking History",
                    description: "Track all your parking sessions",
                    color: .pink
                )
            }
        }
    }
    
    private func featureRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                    
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SubscriptionView()
        .environment(SubscriptionService())
}
