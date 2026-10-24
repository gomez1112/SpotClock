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

@available(iOS 27.1, *)
struct ActiveTimerView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService
    @Environment(LocationService.self) private var locationService
    @Environment(WalkETAService.self) private var walkETAService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var countdownFontSize = 64.0
    
    // ✅ NEW: Separate refresh timer
    @State private var refreshTimer: Timer?
    
    var session: ParkingSession
    
    var body: some View {
        parkingLayout
            .background { AppBackground() }
            .navigationBarTitleDisplayMode(.inline)
            .task(id: session.id) {
                await initialRefresh()
                startRefreshTimer()
            }
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

    @ViewBuilder
    private var parkingLayout: some View {
        if hasCarLocation {
            ArrangementView {
                timerContent
                    .splitArrangementLayoutSize(minWidth: 300)
            } secondary: {
                ParkingLocationView(session: session) {
                    showDirections = true
                }
                .splitArrangementLayoutSize(minWidth: 280)
            }
            // Compact displays keep the timer full height; the inner display can
            // place the map beside it or above/below it around either fold axis.
            .arrangementViewStyle(.split.axes(arrangementAxes))
        } else {
            timerContent
        }
    }

    private var timerContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("PARKED & PRESENT", systemImage: "car.fill")
                            .font(.caption2.weight(.semibold)).tracking(1.5)
                            .foregroundStyle(DesignSystem.warmAccent)
                        Spacer()
                        Text(statusText).font(.caption.weight(.medium))
                            .foregroundStyle(timeColor)
                    }
                    Text("Enjoy your time.")
                        .font(.system(.largeTitle, design: .serif)).tracking(-0.8)
                    Text(session.location.isEmpty ? "Your parking timer is running." : session.location)
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ParkingDialView(
                    progress: timerService.timeRemaining / max(1, session.duration),
                    time: formatTimeRemaining(timerService.timeRemaining),
                    caption: "time remaining", maximumDiameter: 220
                )

                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("RETURN BY").font(.caption2.weight(.semibold)).tracking(1.5)
                        Text(session.endTime, format: .dateTime.hour().minute())
                            .font(.system(.title2, design: .serif))
                    }
                    Spacer()
                    Image(systemName: "bell.badge.fill").font(.title3)
                }
                .foregroundStyle(.white).padding(16)
                .background(DesignSystem.ink, in: .rect(cornerRadius: 20))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Stay a little longer.").font(.subheadline.weight(.medium))
                    let layout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(spacing: 12))
                        : AnyLayout(HStackLayout(spacing: 12))
                    layout {
                        extendButton(minutes: 15, icon: "plus")
                        extendButton(minutes: 30, icon: "plus")
                    }
                    Text("Extends your reminder. Pay the meter separately.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                if !session.notes.isEmpty {
                    Divider()
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "note.text").foregroundStyle(DesignSystem.warmAccent)
                        Text(session.notes).font(.subheadline)
                        Spacer(minLength: 0)
                    }
                }
                HStack {
                    Button("Copy details", systemImage: "document.on.document") { copyParkingDetails() }
                        .sensoryFeedback(.success, trigger: copyHapticTick)
                    Spacer()
                    Button("End parking", systemImage: "stop.fill", role: .destructive) {
                        endHapticTick += 1
                        timerService.stopParking()
                    }
                    .accessibilityIdentifier("parking.end")
                    .sensoryFeedback(.success, trigger: endHapticTick)
                }
                .font(.subheadline).buttonStyle(.borderless)
                .padding(.vertical, 10)
                if let copiedDetailsMessage {
                    Text(copiedDetailsMessage).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .appContentWidth(540)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            if hasCarLocation {
                Button { showDirections = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.walk").font(.title2)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Return to your car").font(.headline)
                            if let leaveBy {
                                Text("Leave by \(leaveBy.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundStyle(.primary).padding(18)
                    .background(DesignSystem.cardBackground, in: .rect(cornerRadius: 20))
                    .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(DesignSystem.warmAccent.opacity(0.25)) }
                }
                .buttonStyle(.plain).padding(.horizontal, 24).padding(.vertical, 12)
                .appContentWidth(540).background(DesignSystem.appBackground)
                .accessibilityHint("Opens walking directions to your saved parking location.")
            }
        }
    }

    private var hasCarLocation: Bool {
        session.latitude != 0 && session.longitude != 0
    }

    private var arrangementAxes: Axis.Set {
        if horizontalSizeClass == .regular {
            return [.horizontal, .vertical]
        }
        return .horizontal
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
        if timerService.timeRemaining > 600 { return DesignSystem.brandTeal }
        else if timerService.timeRemaining > 300 { return .orange }
        else { return .red }
    }
    
    private var statusText: String {
        if timerService.timeRemaining > 600 { return "Timer active" }
        else if timerService.timeRemaining > 300 { return "Return soon" }
        else { return "Time is nearly up" }
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
            return "\(hours):\(twoDigit(minutes)):\(twoDigit(seconds))"
        } else {
            return "\(minutes):\(twoDigit(seconds))"
        }
    }

    private func twoDigit(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
    
    private func extendButton(minutes: Int, icon: String) -> some View {
        Button {
            extendHapticTick += 1
            timerService.extendParking(by: TimeInterval(minutes * 60))
        } label: {
            Label("\(minutes) min", systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(DesignSystem.brandBlue)
                .background(DesignSystem.softAccent, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: extendHapticTick)
        .accessibilityLabel("Extend parking by \(minutes) minutes")
    }
}
