//
//  PreviewData.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import Foundation
import SwiftData
import SwiftUI

struct PreviewData: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        ModelContainerFactory.createPreviewContainer
    }
    func body(content: Content, context: ModelContainer) -> some View {
        content
            .modelContainer(context)
            .environment(TimerService(container: context))
            .environment(SubscriptionService())
            .environment(LocationService())
            .environment(WalkETAService())
            
    }
}
extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var previewData: Self = .modifier(PreviewData())
}
