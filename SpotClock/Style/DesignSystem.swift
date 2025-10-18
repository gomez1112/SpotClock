//
//  DesignSystem.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//


import SwiftUI

struct DesignSystem {
    static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.3, green: 0.4, blue: 0.9), Color(red: 0.5, green: 0.3, blue: 0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color.green, Color.green.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let meshGradient = MeshGradient(
        width: 3,
        height: 3,
        points: [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
            .init(0, 1), .init(0.5, 1), .init(1, 1)
        ],
        colors: [
            .blue, .blue.opacity(0.8), .purple,
            .blue.opacity(0.7), .purple.opacity(0.3), .purple.opacity(0.7),
            .indigo, .purple.opacity(0.8), .purple
        ]
    )
    
    static let cardBackground = Color(uiColor: .systemBackground).opacity(0.95)
    
    static let presetDurations: [(title: String, duration: TimeInterval, icon: String)] = [
        ("15 min", 900, "15.circle.fill"),
        ("30 min", 1800, "30.circle.fill"),
        ("1 hour", 3600, "clock.fill"),
        ("2 hours", 7200, "clock.arrow.circlepath"),
        ("4 hours", 14400, "hourglass"),
    ]
}
