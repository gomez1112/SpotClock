//
//  ParkingRecommendationEngine.swift
//  SpotClock
//
//  Created by Codex on 3/8/26.
//

import Foundation

struct ParkingDurationSuggestion: Identifiable, Equatable {
    let duration: TimeInterval
    let detail: String

    var id: Int { Int(duration) }

    var title: String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0, minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        } else {
            return "\(totalMinutes) min"
        }
    }
}

enum ParkingRecommendationEngine {
    static func suggestions(
        from sessions: [ParkingSession],
        now: Date = .now,
        limit: Int = 3
    ) -> [ParkingDurationSuggestion] {
        guard !sessions.isEmpty else { return [] }

        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentHour = calendar.component(.hour, from: now)

        var buckets: [TimeInterval: SuggestionStats] = [:]

        for session in sessions {
            guard session.duration >= 15 * 60 else { continue }

            let bucket = bucketedDuration(for: session.duration)
            let daysAgo = max(0, calendar.dateComponents([.day], from: session.startTime, to: now).day ?? 0)
            let sessionWeekday = calendar.component(.weekday, from: session.startTime)
            let sessionHour = calendar.component(.hour, from: session.startTime)
            let hourDistance = min(abs(sessionHour - currentHour), 24 - abs(sessionHour - currentHour))

            let recencyScore: Double
            switch daysAgo {
            case 0..<14:
                recencyScore = 3
            case 14..<45:
                recencyScore = 2
            default:
                recencyScore = 1
            }

            let weekdayScore = sessionWeekday == currentWeekday ? 2.5 : 0
            let hourScore: Double
            switch hourDistance {
            case 0...1:
                hourScore = 2.5
            case 2...3:
                hourScore = 1.5
            default:
                hourScore = 0
            }

            var stats = buckets[bucket, default: SuggestionStats()]
            stats.score += 1 + recencyScore + weekdayScore + hourScore
            stats.count += 1
            stats.sameWeekdayCount += sessionWeekday == currentWeekday ? 1 : 0
            stats.similarHourCount += hourDistance <= 1 ? 1 : 0
            stats.recentCount += daysAgo < 30 ? 1 : 0
            buckets[bucket] = stats
        }

        return buckets
            .sorted {
                if $0.value.score == $1.value.score {
                    if $0.value.count == $1.value.count {
                        return $0.key < $1.key
                    }
                    return $0.value.count > $1.value.count
                }
                return $0.value.score > $1.value.score
            }
            .prefix(limit)
            .map { duration, stats in
                ParkingDurationSuggestion(duration: duration, detail: detail(for: stats))
            }
    }

    static func bucketedDuration(for duration: TimeInterval) -> TimeInterval {
        let bucketSize: TimeInterval = 15 * 60
        return max(bucketSize, (duration / bucketSize).rounded() * bucketSize)
    }

    private static func detail(for stats: SuggestionStats) -> String {
        if stats.sameWeekdayCount > 0, stats.similarHourCount > 0 {
            return "Matches your usual parking time"
        }
        if stats.recentCount > 1 {
            return "Based on recent parking sessions"
        }
        if stats.count > 1 {
            return "A common duration in your history"
        }
        return "Suggested from your last session"
    }
}

private struct SuggestionStats {
    var score: Double = 0
    var count = 0
    var sameWeekdayCount = 0
    var similarHourCount = 0
    var recentCount = 0
}
