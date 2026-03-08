//
//  DebugSampleDataSeeder.swift
//  SpotClock
//
//  Created by Codex on 3/8/26.
//

import Foundation
import SwiftData

#if DEBUG
@MainActor
enum DebugSampleDataSeeder {
    private static let storedIDsKey = "debugSampleSessionIDs"

    static func generateSessions(count: Int, into modelContext: ModelContext) throws -> Int {
        let templates = SessionTemplate.templates
        let now = Date()
        var generatedIDs = storedSessionIDs()

        for index in 0..<count {
            let template = templates[index % templates.count]
            let weekOffset = index / templates.count
            let daysAgo = min(180, template.daysAgo + weekOffset * 7)

            guard
                let startTime = makeDate(
                    from: now,
                    daysAgo: daysAgo,
                    hour: template.startHour,
                    minute: template.startMinute
                )
            else {
                continue
            }

            let durationMinutes = template.durationMinutes + ((index / 9) % 3) * 15
            let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
            let notes = sampleNote(for: template, index: index)
            let sessionID = UUID()

            let session = ParkingSession(
                id: sessionID,
                startTime: startTime,
                endTime: endTime,
                duration: TimeInterval(durationMinutes * 60),
                location: template.location,
                latitude: template.latitude,
                longitude: template.longitude,
                notes: notes,
                wasExtended: template.wasExtended || index.isMultiple(of: 6),
                notificationSent: true
            )

            modelContext.insert(session)
            generatedIDs.append(sessionID)
        }

        try modelContext.save()
        storeSessionIDs(generatedIDs)
        return count
    }

    static func clearGeneratedSessions(from modelContext: ModelContext) throws -> Int {
        let idsToDelete = Set(storedSessionIDs())
        guard !idsToDelete.isEmpty else { return 0 }

        let descriptor = FetchDescriptor<ParkingSession>()
        let sessions = try modelContext.fetch(descriptor)
        let generatedSessions = sessions.filter { idsToDelete.contains($0.id) }

        for session in generatedSessions {
            modelContext.delete(session)
        }

        try modelContext.save()
        storeSessionIDs([])
        return generatedSessions.count
    }

    static var generatedSessionCount: Int {
        storedSessionIDs().count
    }

    private static func makeDate(from now: Date, daysAgo: Int, hour: Int, minute: Int) -> Date? {
        let calendar = Calendar.current
        guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) else {
            return nil
        }

        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }

    private static func sampleNote(for template: SessionTemplate, index: Int) -> String {
        let notePool = [
            "",
            "Lunch meeting",
            "Errands downtown",
            "Workout session",
            "Dinner reservation",
            "Client meeting",
            "Concert night",
            "Office commute"
        ]

        if template.defaultNote.isEmpty {
            return notePool[index % notePool.count]
        } else if index.isMultiple(of: 4) {
            return template.defaultNote
        } else {
            return ""
        }
    }

    private static func storedSessionIDs() -> [UUID] {
        guard let data = UserDefaults.standard.data(forKey: storedIDsKey) else {
            return []
        }

        return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
    }

    private static func storeSessionIDs(_ ids: [UUID]) {
        let uniqueIDs = Array(Set(ids))
        if let data = try? JSONEncoder().encode(uniqueIDs) {
            UserDefaults.standard.set(data, forKey: storedIDsKey)
        }
    }
}

private struct SessionTemplate {
    let location: String
    let latitude: Double
    let longitude: Double
    let startHour: Int
    let startMinute: Int
    let durationMinutes: Int
    let daysAgo: Int
    let wasExtended: Bool
    let defaultNote: String

    static let templates: [SessionTemplate] = [
        SessionTemplate(location: "Downtown Plaza Garage", latitude: 34.0522, longitude: -118.2437, startHour: 9, startMinute: 0, durationMinutes: 120, daysAgo: 1, wasExtended: false, defaultNote: "Client meeting"),
        SessionTemplate(location: "Downtown Plaza Garage", latitude: 34.0522, longitude: -118.2437, startHour: 13, startMinute: 15, durationMinutes: 135, daysAgo: 3, wasExtended: true, defaultNote: ""),
        SessionTemplate(location: "Westfield Shopping Center", latitude: 34.0622, longitude: -118.2537, startHour: 16, startMinute: 30, durationMinutes: 90, daysAgo: 2, wasExtended: false, defaultNote: "Groceries"),
        SessionTemplate(location: "Office Building Parking", latitude: 34.0422, longitude: -118.2337, startHour: 8, startMinute: 0, durationMinutes: 480, daysAgo: 4, wasExtended: false, defaultNote: "Full workday"),
        SessionTemplate(location: "Third Street Promenade", latitude: 34.0157, longitude: -118.4961, startHour: 19, startMinute: 0, durationMinutes: 110, daysAgo: 6, wasExtended: false, defaultNote: "Dinner with friends"),
        SessionTemplate(location: "Beach Parking Lot", latitude: 34.0095, longitude: -118.4968, startHour: 11, startMinute: 0, durationMinutes: 150, daysAgo: 9, wasExtended: false, defaultNote: "Weekend beach day"),
        SessionTemplate(location: "Fitness Center Parking", latitude: 34.0522, longitude: -118.2537, startHour: 6, startMinute: 45, durationMinutes: 75, daysAgo: 11, wasExtended: false, defaultNote: "Morning workout"),
        SessionTemplate(location: "Movie Theater Complex", latitude: 34.0722, longitude: -118.2637, startHour: 20, startMinute: 0, durationMinutes: 165, daysAgo: 13, wasExtended: false, defaultNote: "Movie night"),
        SessionTemplate(location: "LAX Terminal 3 Parking", latitude: 33.9416, longitude: -118.4085, startHour: 5, startMinute: 30, durationMinutes: 180, daysAgo: 15, wasExtended: false, defaultNote: "Airport run"),
        SessionTemplate(location: "Civic Center Garage", latitude: 34.0537, longitude: -118.2428, startHour: 10, startMinute: 0, durationMinutes: 140, daysAgo: 17, wasExtended: true, defaultNote: ""),
        SessionTemplate(location: "Arts District Lot", latitude: 34.0339, longitude: -118.2295, startHour: 18, startMinute: 15, durationMinutes: 100, daysAgo: 20, wasExtended: false, defaultNote: "Gallery stop"),
        SessionTemplate(location: "Staples Event Parking", latitude: 34.0430, longitude: -118.2673, startHour: 17, startMinute: 45, durationMinutes: 210, daysAgo: 22, wasExtended: true, defaultNote: "Event parking")
    ]
}
#endif
