//
//  ActiveTimerView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/13/25.
//

import MapKit
import SwiftData
import SwiftUI

struct ActiveTimerView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService
    @Environment(LocationService.self) private var locationService
    @Environment(WalkETAService.self) private var walkETAService
    
    @State private var walkingETA: TimeInterval? = nil
    @State private var leaveBy: Date? = nil
    @State private var lastScheduledLeaveBy: Date? = nil
    

    @State private var bearing: Double = 0.0
    @State private var distance: Double = 0.0
    
    @State private var extendHapticTick: Int = 0
    @State private var endHapticTick: Int = 0
    
    var session: ParkingSession
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Spacer(minLength: 8)
                    
                    // Time remaining with enhanced visual hierarchy
                    VStack {
                        Text("Time Remaining")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        // Large timer display
                        Text(formatTimeRemaining(timerService.timeRemaining))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(timeColor)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.smooth, value: timerService.timeRemaining)
                        
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
                    
                    DualRingView(outerProgress: CGFloat(timerService.timeRemaining / max(1, session.duration)), innerProgress: LeaveNowAdvisor.innerRingProgress(leaveBy: leaveBy, sessionStart: session.startTime, sessionDuration: session.duration))
                    
                    
                    HStack {
                        LeaveNowTile(leaveBy: leaveBy, isGoNow: (leaveBy ?? .distantPast) <= Date())
                            .sensoryFeedback(.success, trigger: (leaveBy ?? .distantPast) <= Date())
                        if hasCarLocation, distance > 0 {
                            CompassToCar(bearingRadians: bearing, distanceMeters: distance)
                        }
                    }
                    .padding(.horizontal)
                   // RingProgressView()
                    
                    // Action buttons with improved layout
                    VStack {
                        HStack {
                            extendButton(minutes: 15, icon: "15.circle.fill")
                            extendButton(minutes: 30, icon: "30.circle.fill")
                        }
                        
                        Button(role: .destructive) {
                            endHapticTick += 1
                            
                            if let session = timerService.activeSession {
                                modelContext.insert(session)
                            }
                            timerService.stopParking()
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
            .task(id: timerService.timeRemaining) {
                await refreshETAAndCompass()
            }
            .task {
                await refreshETAAndCompass()
            }
        }
        
    }
    private var hasCarLocation: Bool {
        session.latitude != 0 && session.longitude != 0
    }
    
    private func refreshETAAndCompass() async {
        guard hasCarLocation else { return }
        guard let userCoord = locationService.location?.coordinate else { return }
        
        let car = CLLocationCoordinate2D(latitude: session.latitude, longitude: session.longitude)
        
        // Distance + bearing for compass
        let dist = GeoUtils.distanceMeters(from: userCoord, to: car)
        let bear = GeoUtils.bearingRadians(from: userCoord, to: car)
        await MainActor.run {
            distance = dist
            bearing = bear
        }
        
        // Walking ETA
        if let eta = await walkETAService.etaSeconds(from: userCoord, to: car) {
            let newLeaveBy = LeaveNowAdvisor.leaveBy(expiry: session.endTime, walkingETA: eta)
            await MainActor.run {
                walkingETA = eta
                leaveBy = newLeaveBy
            }
            
            // Schedule or reschedule leave-now alarm if changed materially (≥ 30s delta)
            let delta = abs((lastScheduledLeaveBy ?? .distantPast).timeIntervalSince(newLeaveBy))
            if lastScheduledLeaveBy == nil || delta > 30 {
                timerService.updateLeaveNowAlarm(leaveBy: newLeaveBy > Date() ? newLeaveBy : nil)
                lastScheduledLeaveBy = newLeaveBy
            }
        }
    }
    private var timeColor: Color {
        if timerService.timeRemaining > 600 { return .green }
        else if timerService.timeRemaining > 300 { return .orange }
        else { return .red }
    }
    
    private var statusText: String {
        if timerService.timeRemaining > 600 { return "All Good" }
        else if timerService.timeRemaining > 300 { return "Heads Up" }
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
            timerService.extendParking(by: TimeInterval(minutes * 60))
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

#Preview(traits: .previewData) {
    NavigationStack {
        ActiveTimerView(session: ParkingSession(endTime: Date(), duration: 2000))
            .environment(TimerService(container: ModelContainerFactory.createPreviewContainer))
    }
}

