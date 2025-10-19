//
//  ModelContainerFactory.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//


import Foundation
import SwiftData

@MainActor
struct ModelContainerFactory {
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
            // Log the full error, not just localizedDescription
            print("ModelContainer creation failed: \(error)")
            if let sdError = error as? SwiftDataError {
                print("SwiftDataError: \(sdError)") // often reveals the specific case
            }
            fatalError("Could not create model container: \(error.localizedDescription)")
        }
    }()

    static func createPreviewContainer() throws -> ModelContainer {
        let container = try ModelContainer(for: schema, configurations: configuration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Insert sample data for all models
        context.insert(ParkingSession.sampleParkingSession)
        
        try context.save()
        return container
    }
}
