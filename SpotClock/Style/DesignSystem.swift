//
//  DesignSystem.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//


import SwiftUI

struct DesignSystem {
    static let maxContentWidth: CGFloat = 760
    static let maxWideContentWidth: CGFloat = 1040
    static let maxRouteSummaryWidth: CGFloat = 460
    static let overlaidRouteSummaryHeightFraction: CGFloat = 0.45
    static let screenPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 24

    static let brandBlue = Color.accentColor
    static let brandTeal = Color(red: 0.28, green: 0.48, blue: 0.43)
    static let brandIndigo = Color(red: 0.12, green: 0.22, blue: 0.30)
    static let warmAccent = Color("Brass")
    static let ink = Color(red: 0.08, green: 0.14, blue: 0.21)
    static let lavender = Color(red: 0.82, green: 0.75, blue: 0.61)
    static let mint = Color(red: 0.79, green: 0.87, blue: 0.82)
    static let softAccent = Color("SoftAccent")

    static let primaryGradient = LinearGradient(
        colors: [ink, brandIndigo],
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
    
    static let cardBackground = Color("Surface")
    static let elevatedCardBackground = Color("Surface")

    static let appBackground = Color("Canvas")

    static func cardStroke(_ opacity: Double = 0.08) -> Color {
        Color.primary.opacity(opacity)
    }
    
    static var presetDurations: [(title: String, duration: TimeInterval, icon: String)] {
        // Define the standard list of durations for all users.
        var durations: [(title: String, duration: TimeInterval, icon: String)] = [
            ("15 min", 900, "15.circle.fill"),
            ("30 min", 1800, "30.circle.fill"),
            ("1 hour", 3600, "clock.fill"),
            ("2 hours", 7200, "clock.arrow.circlepath"),
            ("4 hours", 14400, "hourglass"),
        ]
        
        // ✅ ADDED: This block only runs for debug builds (Xcode/Simulator/Previews).
        // It inserts the 15-second timer at the beginning of the list.
#if DEBUG
        durations.insert(("15 sec", 15, "hare.fill"), at: 0)
#endif
        
        return durations
    }
}
