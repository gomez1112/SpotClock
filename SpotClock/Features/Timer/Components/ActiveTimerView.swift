//
//  ActiveTimerView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/13/25.
//

import SwiftData
import SwiftUI
struct ActiveTimerView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerManager
    
    @State private var extendHapticTick: Int = 0
    @State private var endHapticTick: Int = 0
    
    var session: ParkingSession
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Spacer()
                    
                    // Time remaining with enhanced visual hierarchy
                    VStack {
                        Text("Time Remaining")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        // Large timer display
                        Text(formatTimeRemaining(timerManager.timeRemaining))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(timeColor)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.smooth, value: timerManager.timeRemaining)
                        
                        // Status indicator
                        HStack {
                            Circle()
                                .fill(timeColor)
                                .frame(width: 8, height: 8)
                            Text(statusText)
                                .font(.subheadline)
                                .foregroundStyle(timeColor)
                        }
                        .padding()
                        .background(timeColor.opacity(0.1), in: Capsule())
                    }
                    .padding()
                    
                    // Enhanced progress ring with better styling
                    RingProgressView()
                    
                    // Action buttons with improved layout
                    VStack {
                        HStack {
                            extendButton(minutes: 15, icon: "15.circle.fill")
                            extendButton(minutes: 30, icon: "30.circle.fill")
                        }
                        
                        Button(role: .destructive) {
                            endHapticTick += 1
                            
                            if let session = timerManager.activeSession {
                                modelContext.insert(session)
                            }
                            timerManager.stopParking()
                        } label: {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title3)
                                Text("End Parking")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical)
                            .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
                        }
                        .tint(.red)
                        .buttonSizing(.flexible)
                        .buttonStyle(.borderedProminent)
                        .sensoryFeedback(.success, trigger: endHapticTick)
                    }
                    .padding()
                    
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .scrollBounceBehavior(.basedOnSize)
        }
        
    }

    private var timeColor: Color {
        if timerManager.timeRemaining > 600 { return .green }
        else if timerManager.timeRemaining > 300 { return .orange }
        else { return .red }
    }
    
    private var statusText: String {
        if timerManager.timeRemaining > 600 { return "All Good" }
        else if timerManager.timeRemaining > 300 { return "Heads Up" }
        else { return "Time Running Out!" }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    private func extendButton(minutes: Int, icon: String) -> some View {
        Button {
            extendHapticTick += 1
            timerManager.extendParking(by: TimeInterval(minutes * 60))
        } label: {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                Text("+\(minutes) min")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.white)
            .padding(1)
            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
        .tint(.blue)
        .buttonSizing(.flexible)
        .buttonStyle(.borderedProminent)
        .sensoryFeedback(.impact(weight: .light), trigger: extendHapticTick)
    }
}

#Preview {
    NavigationStack {
        ActiveTimerView(session: ParkingSession(endTime: Date(), duration: 2000))
            .environment(TimerService())
    }
}

