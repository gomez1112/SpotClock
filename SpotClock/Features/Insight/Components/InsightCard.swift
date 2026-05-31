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
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(colors: [insight.color.opacity(0.95), insight.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                Image(systemName: insight.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)
            .shadow(color: insight.color.opacity(0.18), radius: 10, x: 0, y: 6)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
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
        .accessibilityHint("Opens details")
    }
}

#Preview {
    InsightCard(insight: Insight(icon: "house", title: "House", description: "This is a house", color: .blue))
}
