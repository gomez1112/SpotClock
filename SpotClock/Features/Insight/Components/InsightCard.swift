//
//  InsightCard.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import SwiftUI

struct InsightCard: View {

    let insight: Insight
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundStyle(DesignSystem.warmAccent)
                .frame(width: 44, height: 44)
                .background(DesignSystem.softAccent, in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.headline)

                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                Text(insight.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            }

            Spacer()
        }
        .padding()
        .appCard(fill: DesignSystem.elevatedCardBackground, cornerRadius: 20)
        .scaleEffect(appeared ? 1 : 0.98)
        .opacity(appeared ? 1 : 0)
        .animation(reduceMotion ? .default : .spring(response: 0.5, dampingFraction: 0.8), value: appeared)
        .onAppear { appeared = true }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .hoverEffect(.lift)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.title). \(insight.description)")

    }
}
