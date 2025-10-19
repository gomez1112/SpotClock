//
//  LeaveNowAdvisor.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//


import Foundation

enum LeaveNowAdvisor {
    /// Compute the Date the user should start walking so they arrive before expiry with a safety buffer.
    static func leaveBy(
        expiry: Date,
        walkingETA: TimeInterval,
        safetyBuffer: TimeInterval = 3 * 60 // 3 min default
    ) -> Date {
        expiry.addingTimeInterval(-(walkingETA + safetyBuffer))
    }

    /// Clamp inner-ring progress for “time until leave-by” vs total duration.
    static func innerRingProgress(
        leaveBy: Date?,
        sessionStart: Date,
        sessionDuration: TimeInterval
    ) -> CGFloat {
        guard sessionDuration > 0, let leaveBy else { return 0 }
        let total = sessionDuration
        let elapsed = max(0, Date().timeIntervalSince(sessionStart))
        let untilLeave = max(0, leaveBy.timeIntervalSinceNow)
        // Represent inner ring as proportion of total: remaining-to-leave over total
        let remainingOfTotal = max(0, total - elapsed - (total - untilLeave)) // simplifies to untilLeave if <= total
        let p = min(1, max(0, remainingOfTotal / total))
        return CGFloat(p)
    }
}
