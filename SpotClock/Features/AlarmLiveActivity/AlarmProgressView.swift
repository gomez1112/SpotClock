//
//  AlarmProgressView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/18/25.
//

import AlarmKit
import SwiftUI

struct AlarmProgressView: View {
    var mode: AlarmPresentationState.Mode
    var tint: Color
    
    var body: some View {
        Group {
            switch mode {
            case .countdown(let countdown):
                ProgressView(
                    timerInterval: Date.now ... countdown.fireDate,
                    countsDown: true,
                    label: { EmptyView() },
                    currentValueLabel: {
                        Image(systemName: "parkingsign")
                            .scaleEffect(0.9)
                    })
            case .paused(let pausedState):
                let remaining = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
                ProgressView(value: remaining,
                             total: pausedState.totalCountdownDuration,
                             label: { EmptyView() },
                             currentValueLabel: {
                    Image(systemName: "pause.fill")
                        .scaleEffect(0.8)
                })
            default:
                EmptyView()
            }
        }
        .progressViewStyle(.circular)
        .foregroundStyle(tint)
        .tint(tint)
    }
}
