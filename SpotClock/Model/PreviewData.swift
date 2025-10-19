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
        try ModelContainerFactory.createPreviewContainer()
    }
    func body(content: Content, context: ModelContainer) -> some View {
        content
            .modelContainer(context)
            .environment(TimerService())
            .environment(SubscriptionService())
            .environment(LocationService())
            
    }
}
extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var previewData: Self = .modifier(PreviewData())
}
