//
//  ParkingSession.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//


import Foundation
import SwiftData
import CoreLocation

typealias ParkingSession = ParkingSessionV1.ParkingSession
enum ParkingSessionV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [ParkingSession.self]
    }
    
    @Model
    final class ParkingSession {
        var id: UUID
        var startTime: Date
        var endTime: Date
        var duration: TimeInterval
        var location: String
        var latitude: Double
        var longitude: Double
        var notes: String
        var wasExtended: Bool
        var notificationSent: Bool
        
        init(
            id: UUID = UUID(),
            startTime: Date = Date(),
            endTime: Date,
            duration: TimeInterval,
            location: String = "",
            latitude: Double = 0,
            longitude: Double = 0,
            notes: String = "",
            wasExtended: Bool = false,
            notificationSent: Bool = false
        ) {
            self.id = id
            self.startTime = startTime
            self.endTime = endTime
            self.duration = duration
            self.location = location
            self.latitude = latitude
            self.longitude = longitude
            self.notes = notes
            self.wasExtended = wasExtended
            self.notificationSent = notificationSent
        }
        
        var timeRemaining: TimeInterval {
            max(0, endTime.timeIntervalSince(Date()))
        }
        
        var isActive: Bool {
            timeRemaining > 0
        }
        
        var isExpired: Bool {
            timeRemaining <= 0
        }
    }
}
