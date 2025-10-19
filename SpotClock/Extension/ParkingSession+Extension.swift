//
//  ParkingSession+Extension.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import Foundation

extension ParkingSession {
    // Assuming the ParkingSession structure from your prompt is available.
    
    // Helper to create a date two hours in the past
    static let pastDate = Date().addingTimeInterval(-2 * 3600) // 2 hours ago
    
    // Helper to calculate the original end time (2 hours after start)
    static let originalEndTime = pastDate.addingTimeInterval(2 * 3600)
    
    // Helper to calculate the extended end time (3 hours after start)
    static let extendedEndTime = pastDate.addingTimeInterval(3 * 3600)
    
    // 2. Create the sample ParkingSession instance
    @MainActor static let sampleParkingSession = ParkingSession(
        // id: UUID() is typically handled by the default initializer, but we can set one explicitly for a clear sample.
        id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3F6E22")!,
        startTime: pastDate,
        endTime: extendedEndTime,
        duration: 3 * 3600, // 3 hours in seconds (2 hours original + 1 hour extension)
        location: "City Garage B, Level 3",
        latitude: 34.0522, // Los Angeles latitude for example
        longitude: -118.2437, // Los Angeles longitude for example
        notes: "Remember to move the car before 1:00 PM.",
        wasExtended: true,
        notificationSent: true
    )
}
