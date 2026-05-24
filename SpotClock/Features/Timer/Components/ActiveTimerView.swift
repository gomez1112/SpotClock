//
//  ActiveTimerView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/13/25.
//

import MapKit
import SwiftData
import SwiftUI
import UIKit

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
    @State private var copyHapticTick: Int = 0
    
    @State private var lastUserLocation: CLLocationCoordinate2D?
    @State private var isSchedulingLeaveAlarm = false
    
    @State private var showDirections = false
    @State private var lastSessionEndTime: Date?
    @State private var copiedDetailsMessage: String?
    
    // ✅ NEW: Separate refresh timer
    @State private var refreshTimer: Timer?
    
    var session: ParkingSession
    
    var body: some View {
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
                    LeaveNowTile(
                        leaveBy: leaveBy,
                        isGoNow: (leaveBy ?? .distantPast) <= Date()
                    ) {
                        if hasCarLocation {
                            showDirections = true
                        }
                    }
                    .sensoryFeedback(.success, trigger: (leaveBy ?? .distantPast) <= Date())
                    
                    if hasCarLocation, distance > 0 {
                        CompassToCar(bearingRadians: bearing, distanceMeters: distance)
                    }
                }
                .padding(.horizontal)
            }
            
            // Action buttons with improved layout
            VStack {
                HStack {
                    extendButton(minutes: 15, icon: "15.circle.fill")
                    extendButton(minutes: 30, icon: "30.circle.fill")
                }
                
                Button(role: .destructive) {
                    endHapticTick += 1
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
                .accessibilityHint("Ends the current parking timer.")

                Button {
                    copyParkingDetails()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                        Text("Copy Parking Details")
                            .font(.headline)
                    }
                    .foregroundStyle(.blue)
                    .padding(.vertical)
                }
                .buttonSizing(.flexible)
                .buttonStyle(.bordered)
                .sensoryFeedback(.success, trigger: copyHapticTick)
                .accessibilityHint("Copies your parking location, expiry time, and notes.")

                if let copiedDetailsMessage {
                    Text(copiedDetailsMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                        .accessibilityLabel(copiedDetailsMessage)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .scrollBounceBehavior(.basedOnSize)
        // ✅ FIXED: Don't use timeRemaining in task ID - it changes every second!
        .task(id: session.id) {
            await initialRefresh()
            startRefreshTimer()
        }
        // ✅ FIXED: Watch for session end time changes (from extensions)
        .onChange(of: session.endTime) { oldValue, newValue in
            if oldValue != newValue {
                Task {
                    await refreshETAAndCompass(forceUpdate: true)
                }
            }
        }
        .onDisappear {
            stopRefreshTimer()
            locationService.stopUpdatingLocation()
        }
        .sheet(isPresented: $showDirections) {
            if hasCarLocation {
                DirectionsMapView(
                    carLocation: CLLocationCoordinate2D(
                        latitude: session.latitude,
                        longitude: session.longitude
                    ),
                    carAddress: session.location
                )
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private var hasCarLocation: Bool {
        session.latitude != 0 && session.longitude != 0
    }
    
    // ✅ NEW: Initial refresh when view appears
    private func initialRefresh() async {
        guard hasCarLocation else { return }
        
        // Start continuous location updates
        await MainActor.run {
            locationService.startUpdatingLocation()
        }
        
        // Get fresh location
        _ = await locationService.ensureLocationName()
        
        // Initial ETA and compass calculation
        await refreshETAAndCompass(forceUpdate: true)
    }
    
    // ✅ NEW: Timer-based refresh (every 10 seconds)
    private func startRefreshTimer() {
        stopRefreshTimer() // Clean up any existing timer
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task { @MainActor in
                await self.refreshETAAndCompass(forceUpdate: false)
            }
        }
        
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // ✅ NEW: Stop the refresh timer
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // ✅ FIXED: Simplified refresh logic with proper force update handling
    private func refreshETAAndCompass(forceUpdate: Bool) async {
        guard hasCarLocation else { return }
        guard let userCoord = locationService.location?.coordinate else { return }
        
        let car = CLLocationCoordinate2D(latitude: session.latitude, longitude: session.longitude)
        
        // Check if user moved significantly or force update
        let shouldUpdate: Bool
        if forceUpdate {
            shouldUpdate = true
        } else if let lastLocation = lastUserLocation {
            let dist = GeoUtils.distanceMeters(from: lastLocation, to: userCoord)
            shouldUpdate = dist > 10 // User moved more than 10 meters
        } else {
            shouldUpdate = true
        }
        
        guard shouldUpdate else { return }
        
        // Update distance and bearing for compass
        let dist = GeoUtils.distanceMeters(from: userCoord, to: car)
        let bear = GeoUtils.bearingRadians(from: userCoord, to: car)
        
        await MainActor.run {
            distance = dist
            if let bear {
                bearing = bear
            }
            lastUserLocation = userCoord
        }
        
        // Update walking ETA
        if let eta = await walkETAService.etaSeconds(from: userCoord, to: car) {
            let newLeaveBy = LeaveNowAdvisor.leaveBy(expiry: session.endTime, walkingETA: eta)
            
            await MainActor.run {
                walkingETA = eta
                leaveBy = newLeaveBy
            }
            
            // Update leave-now alarm if significantly different or force update
            let delta = abs((lastScheduledLeaveBy ?? .distantPast).timeIntervalSince(newLeaveBy))
            if (forceUpdate || lastScheduledLeaveBy == nil || delta > 30) && !isSchedulingLeaveAlarm {
                await MainActor.run {
                    isSchedulingLeaveAlarm = true
                }
                
                timerService.updateLeaveNowAlarm(leaveBy: newLeaveBy > Date() ? newLeaveBy : nil)
                lastScheduledLeaveBy = newLeaveBy
                
                try? await Task.sleep(for: .milliseconds(500))
                
                await MainActor.run {
                    isSchedulingLeaveAlarm = false
                }
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

    private func copyParkingDetails() {
        UIPasteboard.general.string = parkingDetailsText
        copyHapticTick += 1
        copiedDetailsMessage = "Parking details copied."

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            copiedDetailsMessage = nil
        }
    }

    private var parkingDetailsText: String {
        var details = [
            "SpotClock Parking Details",
            "Location: \(session.location.isEmpty ? "Unknown Location" : session.location)",
            "Expires: \(session.endTime.formatted(date: .abbreviated, time: .shortened))",
            "Time Remaining: \(formatTimeRemaining(timerService.timeRemaining))"
        ]

        if !session.notes.isEmpty {
            details.append("Notes: \(session.notes)")
        }

        return details.joined(separator: "\n")
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
        .accessibilityLabel("Extend parking by \(minutes) minutes")
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        ActiveTimerView(session: ParkingSession(endTime: Date(), duration: 2000))
    }
}
