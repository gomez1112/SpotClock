//
//  AlarmControls.swift
//  SpotClockWidgetExtension
//
//  Created by Gerard Gomez on 10/18/25.
//

import AlarmKit
import SwiftUI

struct AlarmControls: View {
    
    var presentation: AlarmPresentation
    var state: AlarmPresentationState
    
    var body: some View {
        HStack(spacing: 4) {
            switch state.mode {
                case .countdown:
                    ButtonView(config: presentation.countdown?.pauseButton, intent: PauseIntent(alarmID: state.alarmID.uuidString), tint: .indigo)
                case .paused:
                    ButtonView(config: presentation.paused?.resumeButton, intent: ResumeIntent(alarmID: state.alarmID.uuidString), tint: .indigo)
                default:
                    EmptyView()
            }
            ButtonView(config: presentation.alert.stopButton, intent: StopIntent(alarmID: state.alarmID.uuidString), tint: .red)
            .minimumScaleFactor(0.1)
        }
    }
}
