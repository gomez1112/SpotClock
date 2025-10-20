//
//  ParkingSession+Extension.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import Foundation

extension ParkingSession {
    // Helper to create dates
    private static func date(daysAgo: Int, hour: Int = 12) -> Date {
        let calendar = Calendar.current
        let now = Date()
        guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return now }
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = 0
        return calendar.date(from: components) ?? date
    }
    
    // Single sample for quick preview
    @MainActor static let sampleParkingSession = ParkingSession(
        id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3F6E22")!,
        startTime: date(daysAgo: 2, hour: 14),
        endTime: date(daysAgo: 2, hour: 17),
        duration: 3 * 3600,
        location: "City Garage B, Level 3",
        latitude: 34.0522,
        longitude: -118.2437,
        notes: "Remember to move the car before 1:00 PM.",
        wasExtended: true,
        notificationSent: true
    )
    
    // Multiple samples for insights testing
    @MainActor static let sampleSessions: [ParkingSession] = [
        // Downtown parking - frequent location
        ParkingSession(
            startTime: date(daysAgo: 1, hour: 9),
            endTime: date(daysAgo: 1, hour: 11),
            duration: 2 * 3600,
            location: "Downtown Plaza Garage",
            latitude: 34.0522,
            longitude: -118.2437,
            notes: "Meeting with client"
        ),
        ParkingSession(
            startTime: date(daysAgo: 3, hour: 14),
            endTime: date(daysAgo: 3, hour: 16),
            duration: 2 * 3600,
            location: "Downtown Plaza Garage",
            latitude: 34.0522,
            longitude: -118.2437,
            wasExtended: true
        ),
        ParkingSession(
            startTime: date(daysAgo: 5, hour: 10),
            endTime: date(daysAgo: 5, hour: 13),
            duration: 3 * 3600,
            location: "Downtown Plaza Garage",
            latitude: 34.0522,
            longitude: -118.2437
        ),
        
        // Shopping center
        ParkingSession(
            startTime: date(daysAgo: 2, hour: 15),
            endTime: date(daysAgo: 2, hour: 17),
            duration: 2 * 3600,
            location: "Westfield Shopping Center",
            latitude: 34.0622,
            longitude: -118.2537,
            notes: "Grocery shopping"
        ),
        ParkingSession(
            startTime: date(daysAgo: 7, hour: 16),
            endTime: date(daysAgo: 7, hour: 18),
            duration: 2 * 3600,
            location: "Westfield Shopping Center",
            latitude: 34.0622,
            longitude: -118.2537
        ),
        
        // Office parking
        ParkingSession(
            startTime: date(daysAgo: 4, hour: 8),
            endTime: date(daysAgo: 4, hour: 17),
            duration: 9 * 3600,
            location: "Office Building Parking",
            latitude: 34.0422,
            longitude: -118.2337,
            notes: "Full workday"
        ),
        ParkingSession(
            startTime: date(daysAgo: 6, hour: 8),
            endTime: date(daysAgo: 6, hour: 17),
            duration: 9 * 3600,
            location: "Office Building Parking",
            latitude: 34.0422,
            longitude: -118.2337
        ),
        
        // Airport parking
        ParkingSession(
            startTime: date(daysAgo: 10, hour: 6),
            endTime: date(daysAgo: 10, hour: 8),
            duration: 2 * 3600,
            location: "LAX Terminal 3 Parking",
            latitude: 33.9416,
            longitude: -118.4085,
            notes: "Flight to SF"
        ),
        
        // Restaurant/evening
        ParkingSession(
            startTime: date(daysAgo: 8, hour: 19),
            endTime: date(daysAgo: 8, hour: 21),
            duration: 2 * 3600,
            location: "Third Street Promenade",
            latitude: 34.0157,
            longitude: -118.4961,
            notes: "Dinner with friends"
        ),
        
        // Weekend sessions
        ParkingSession(
            startTime: date(daysAgo: 9, hour: 11), // Weekend
            endTime: date(daysAgo: 9, hour: 13),
            duration: 2 * 3600,
            location: "Beach Parking Lot",
            latitude: 34.0095,
            longitude: -118.4968,
            notes: "Beach day"
        ),
        
        // Early morning
        ParkingSession(
            startTime: date(daysAgo: 11, hour: 7),
            endTime: date(daysAgo: 11, hour: 9),
            duration: 2 * 3600,
            location: "Fitness Center Parking",
            latitude: 34.0522,
            longitude: -118.2537,
            notes: "Morning workout"
        ),
        
        // Extended session
        ParkingSession(
            startTime: date(daysAgo: 12, hour: 10),
            endTime: date(daysAgo: 12, hour: 15),
            duration: 5 * 3600,
            location: "Downtown Plaza Garage",
            latitude: 34.0522,
            longitude: -118.2437,
            notes: "All-day event",
            wasExtended: true
        ),
        
        // More downtown to make it top location
        ParkingSession(
            startTime: date(daysAgo: 14, hour: 13),
            endTime: date(daysAgo: 14, hour: 15),
            duration: 2 * 3600,
            location: "Downtown Plaza Garage",
            latitude: 34.0522,
            longitude: -118.2437
        ),
        ParkingSession(
            startTime: date(daysAgo: 16, hour: 14),
            endTime: date(daysAgo: 16, hour: 16),
            duration: 2 * 3600,
            location: "Downtown Plaza Garage",
            latitude: 34.0522,
            longitude: -118.2437,
            wasExtended: true
        ),
        
        // Additional variety
        ParkingSession(
            startTime: date(daysAgo: 18, hour: 20),
            endTime: date(daysAgo: 18, hour: 23),
            duration: 3 * 3600,
            location: "Movie Theater Complex",
            latitude: 34.0722,
            longitude: -118.2637,
            notes: "Movie night"
        )
    ]
}
