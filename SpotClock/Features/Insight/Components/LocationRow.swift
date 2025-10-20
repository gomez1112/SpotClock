//
//  LocationRow.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import MapKit
import SwiftUI

struct LocationRow: View {
    let location: LocationData
    let rank: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank badge with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: rankColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                Text("\(rank)")
                    .font(.headline.bold())
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(location.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "pin.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.caption2)
                        Text("^[\(location.visits) visit](inflect: true)")
                            .font(.caption)
                            .monospacedDigit()
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.caption2)
                        Text(formatDuration(location.averageDuration))
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(rank). \(location.name). \(location.visits) \(location.visits == 1 ? "visit" : "visits"). Average stay \(formatDuration(location.averageDuration)).")
        .padding(.vertical, 8)
    }
    
    private var rankColors: [Color] {
        // Analogous palette with gentle hue shift so differences are noticeable but not jarring.
        // Shift hue from teal-ish (rank 1) toward indigo as rank increases.
        let r = max(0, min(12, rank - 1))

        // Teal(≈0.52) → Blue(≈0.56) → Indigo(≈0.62)
        let hue = min(0.62, 0.52 + 0.008 * Double(r))

        // Slightly reduce saturation and brightness as rank increases
        let saturationBase = max(0.75, 0.95 - 0.015 * Double(r))
        let brightnessTop = max(0.80, 0.92 - 0.01 * Double(r))
        let brightnessBottom = max(0.72, 0.84 - 0.01 * Double(r))

        let start = Color(hue: hue, saturation: saturationBase, brightness: brightnessTop)
        let end = Color(hue: hue, saturation: saturationBase * 0.92, brightness: brightnessBottom)
        return [start, end]
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    LocationRow(location: LocationData(name: "New York", visits: 2, coordinate: CLLocationCoordinate2D(latitude: 0.2933, longitude: 23.2323), averageDuration: 60), rank: 2)
}
