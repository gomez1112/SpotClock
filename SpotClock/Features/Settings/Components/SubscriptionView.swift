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
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("SPOTCLOCK PRO", systemImage: "crown.fill")
                            .font(.caption.bold()).tracking(2)
                            .foregroundStyle(DesignSystem.brandBlue)
                        Text("More freedom.\nLess clock-watching.")
                            .font(.system(.largeTitle, design: .serif))
                            .tracking(-1)
                        Text("Make a little room for wherever the day takes you.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    FeatureSummaryRow(title: "Park as often as you like", detail: "Unlimited parking timers, every month.", symbol: "timer")
                    FeatureSummaryRow(title: "Keep every spot", detail: "Your saved locations and parking history.", symbol: "mappin.and.ellipse")
                    FeatureSummaryRow(title: "Know your routine", detail: "Personal parking insights and smart suggestions.", symbol: "sparkles")
                }
                .padding(28)
                .appContentWidth(600)
            }
            .containerBackground(for: .subscriptionStoreFullHeight) { DesignSystem.appBackground }
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
    
}
