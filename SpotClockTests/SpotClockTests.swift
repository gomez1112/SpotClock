//
//  SpotClockTests.swift
//  SpotClockTests
//
//  Created by Gerard Gomez on 10/12/25.
//

import Foundation
import Testing
@testable import SpotClock

struct SpotClockTests {
    @MainActor @Test func recommendationEnginePrefersRecentMatchingPatterns() async throws {
        let calendar = Calendar.current
        let now = Date(timeIntervalSince1970: 1_762_329_600) // Sunday, Nov 9, 2025 12:00:00 GMT

        let matchingRecent = ParkingSession(
            startTime: calendar.date(byAdding: .day, value: -7, to: now)!,
            endTime: calendar.date(byAdding: .minute, value: 90, to: calendar.date(byAdding: .day, value: -7, to: now)!)!,
            duration: 90 * 60,
            location: "Main Street"
        )

        let matchingOlder = ParkingSession(
            startTime: calendar.date(byAdding: .day, value: -21, to: now)!,
            endTime: calendar.date(byAdding: .minute, value: 85, to: calendar.date(byAdding: .day, value: -21, to: now)!)!,
            duration: 85 * 60,
            location: "Main Street"
        )

        let unrelated = ParkingSession(
            startTime: calendar.date(byAdding: .day, value: -2, to: now)!,
            endTime: calendar.date(byAdding: .minute, value: 30, to: calendar.date(byAdding: .day, value: -2, to: now)!)!,
            duration: 30 * 60,
            location: "Short Stay"
        )

        let suggestions = ParkingRecommendationEngine.suggestions(
            from: [matchingRecent, matchingOlder, unrelated],
            now: now,
            limit: 2
        )

        #expect(suggestions.count == 2)
        let firstSuggestion = try #require(suggestions.first)
        #expect(firstSuggestion.duration == TimeInterval(90 * 60))
        #expect(firstSuggestion.detail == "Matches your usual parking time")
    }

    @MainActor @Test func leaveNowAdvisorSubtractsEtaAndBuffer() async throws {
        let expiry = Date(timeIntervalSince1970: 1_700_000_000)
        let leaveBy = LeaveNowAdvisor.leaveBy(
            expiry: expiry,
            walkingETA: 12 * 60,
            safetyBuffer: 5 * 60
        )

        #expect(leaveBy == expiry.addingTimeInterval(-(17 * 60)))
    }
}
