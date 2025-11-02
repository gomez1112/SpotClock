//
//  ModelContainerFactory.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//


import Foundation
import SwiftData
import OSLog

@MainActor
struct ModelContainerFactory {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SpotClock", category: "ModelContainer")
    static let models: [any PersistentModel.Type] = [ParkingSession.self]
    static let schema = Schema(models)
    static func configuration(isStoredInMemoryOnly: Bool) -> ModelConfiguration {
        ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
    }

    static let createSharedContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: schema,
                configurations: configuration(isStoredInMemoryOnly: false)
            )
        } catch {
            // Log the full error using OSLog
            logger.fault("ModelContainer creation failed: \(String(describing: error), privacy: .public)")
            if let sdError = error as? SwiftDataError {
                logger.error("SwiftDataError: \(String(describing: sdError), privacy: .public)")
            }
            fatalError("Could not create model container: \(error.localizedDescription)")
        }
    }()

    static let createPreviewContainer: ModelContainer = {
        do {
            let container = try ModelContainer(for: schema, configurations: configuration(isStoredInMemoryOnly: true))
            let context = container.mainContext
            
            // Insert sample data for all models
            ParkingSession.sampleSessions.forEach(context.insert)
            
            try context.save()
            return container
        } catch {
            logger.error("Preview ModelContainer creation failed: \(error.localizedDescription, privacy: .public)")
            fatalError("Could not create model container: \(error.localizedDescription)")
        }
        
    }()
}

