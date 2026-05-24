//
//  CompassToCar.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import SwiftUI

struct CompassToCar: View {
    let bearingRadians: Double
    let distanceMeters: Double
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1))
                
                // ✅ FIXED: Show different icon when at destination
                if distanceMeters < 5 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                } else {
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.radians(bearingRadians))
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                        .animation(.smooth, value: bearingRadians)
                }
            }
            Text(distanceString(distanceMeters))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Car compass")
        .accessibilityValue(distanceMeters < 5 ? "You are at your car." : "\(distanceString(distanceMeters)) away")
    }
    
    private func distanceString(_ meters: Double) -> String {
        // ✅ ADD: Special message when at destination
        if meters < 5 {
            return "You're here!"
        } else if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return "\(Int(meters)) m"
        }
    }
}

#Preview {
    CompassToCar(bearingRadians: 0.80, distanceMeters: 50)
}
