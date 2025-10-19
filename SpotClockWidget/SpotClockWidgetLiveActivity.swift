//
//  SpotClockWidgetLiveActivity.swift
//  SpotClockWidget
//
//  Created by Gerard Gomez on 10/18/25.
//

import ActivityKit
import AlarmKit
import WidgetKit
import SwiftUI

struct SpotClockWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<TimerData>.self) { context in
            // The Lock Screen presentation.
            lockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            // The presentations that appear in the Dynamic Island.
            DynamicIsland {
                // The expanded Dynamic Island presentation.
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        alarmTitle(attributes: context.attributes, state: context.state)
                        if let location = context.attributes.metadata?.location, !location.isEmpty {
                            Text(location)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "parkingsign")
                        .padding(.horizontal)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    bottomView(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                // The compact leading presentation.
                countdown(state: context.state, maxWidth: 44)
                    .foregroundStyle(context.attributes.tintColor)
            } compactTrailing: {
                // The compact trailing presentation.
                AlarmProgressView(mode: context.state.mode, tint: context.attributes.tintColor)
            } minimal: {
                // The minimal presentation.
                AlarmProgressView(mode: context.state.mode, tint: context.attributes.tintColor)
            }
            .keylineTint(context.attributes.tintColor)
        }
    }
    
    func lockScreenView(attributes: AlarmAttributes<TimerData>, state: AlarmPresentationState) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    alarmTitle(attributes: attributes, state: state)
                    if let location = attributes.metadata?.location, !location.isEmpty {
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                Image(systemName: "parkingsign")
            }
            
            bottomView(attributes: attributes, state: state)
        }
        .padding(.all, 12)
    }
    
    func bottomView(attributes: AlarmAttributes<TimerData>, state: AlarmPresentationState) -> some View {
        HStack {
            countdown(state: state, maxWidth: 150)
                .font(.system(size: 40, design: .rounded))
            Spacer()
            AlarmControls(presentation: attributes.presentation, state: state)
        }
    }
    
    func countdown(state: AlarmPresentationState, maxWidth: CGFloat = .infinity) -> some View {
        Group {
            switch state.mode {
                case .countdown(let countdown):
                    Text(timerInterval: Date.now ... countdown.fireDate, countsDown: true)
                case .paused(let state):
                    let remaining = Duration.seconds(state.totalCountdownDuration - state.previouslyElapsedDuration)
                    let pattern: Duration.TimeFormatStyle.Pattern = remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                    Text(remaining.formatted(.time(pattern: pattern)))
                default:
                    EmptyView()
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: maxWidth, alignment: .leading)
    }
    
    @ViewBuilder func alarmTitle(attributes: AlarmAttributes<TimerData>, state: AlarmPresentationState) -> some View {
        let title: LocalizedStringResource? = switch state.mode {
            case .countdown:
                attributes.presentation.countdown?.title
            case .paused:
                attributes.presentation.paused?.title
            default:
                nil
        }
        
        Text(title ?? "NA")
            .font(.title3)
            .fontWeight(.semibold)
            .lineLimit(1)
            .padding(.leading, 6)
    }
}

