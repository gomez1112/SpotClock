//
//  TimerManager.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import Foundation
@preconcurrency import AlarmKit
import SwiftUI

nonisolated struct TimerData: AlarmMetadata {}

@Observable
final class TimerManager {
    @ObservationIgnored private let alarmManager = AlarmManager.shared
    
    // Public properties for views
    var activeSession: ParkingSession?
    var timeRemaining: TimeInterval = 0
    var isRunning = false
    var userMessage: String?
    
    // Private properties
    private var tickTimer: Timer?
    private var currentAlarmID: UUID?
    
    // MARK: - Public API
    var onSessionExpired: ((ParkingSession) -> Void)?
    
    func startParking(
        duration: TimeInterval,
        location: String,
        latitude: Double,
        longitude: Double,
        notes: String = ""
    ) async {
        let endTime = Date().addingTimeInterval(duration)
        let session = ParkingSession(
            endTime: endTime,
            duration: duration,
            location: location,
            latitude: latitude,
            longitude: longitude,
            notes: notes
        )
        
        activeSession = session
        timeRemaining = duration
        isRunning = true
        
        // Schedule the alarm
            guard await checkForAuthorization() else {
                userMessage = "Alarm permission required. Enable in Settings."
                return
            }
            await scheduleTimer(for: session)
        
        // Start UI ticker
        startTicking()
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func stopParking() {
        // Cancel any active alarm
        if let alarmID = currentAlarmID {
            Task {
                do {
                    try alarmManager.cancel(id: alarmID)
                    userMessage = "Cancelled alarm."
                } catch {
                    userMessage = "Failed to cancel alarm: \(error.localizedDescription)"
                }
            }
            currentAlarmID = nil
        }
        
        isRunning = false
        timeRemaining = 0
        tickTimer?.invalidate()
        tickTimer = nil
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    func extendParking(by additionalTime: TimeInterval) {
        guard let session = activeSession else { return }
        
        // Update session
        session.endTime = session.endTime.addingTimeInterval(additionalTime)
        session.duration += additionalTime
        session.wasExtended = true
        
        // Cancel old alarm and schedule new one
        Task {
            if let alarmID = currentAlarmID {
                try? alarmManager.cancel(id: alarmID)
            }
            await scheduleTimer(for: session)
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    // MARK: - Private Methods
    
    private func startTicking() {
        guard currentAlarmID != nil else {
            userMessage = "Alarm not scheduled - timer will not start."
            return
        }
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateRemaining()
            }
        }
    }
    
    private func updateRemaining() {
        guard let session = activeSession else { return }
        let remaining = max(0, session.endTime.timeIntervalSinceNow)
        timeRemaining = remaining
        
        if remaining <= 0 {
            isRunning = false
            tickTimer?.invalidate()
            
            onSessionExpired?(session)
            activeSession = nil
        }
    }
    
    private func checkForAuthorization() async -> Bool {
        switch alarmManager.authorizationState {
            case .notDetermined:
                do {
                    let state = try await alarmManager.requestAuthorization()
                    return state == .authorized
                } catch {
                    userMessage = "Authorization error: \(error.localizedDescription)"
                    return false
                }
            case .authorized:
                return true
            case .denied:
                return false
            @unknown default:
                return false
        }
    }
    
    private func scheduleTimer(for session: ParkingSession) async {
        // Calculate duration from now to end time
        let duration = session.endTime.timeIntervalSinceNow
        guard duration > 0 else {
            userMessage = "Session already expired; not scheduling alarm."
            return
        }
        
        // Create alert presentation
        let alert = AlarmPresentation.Alert(
            title: "🚨 Parking Expired!",
            stopButton: AlarmButton(
                text: "Dismiss",
                textColor: .white,
                systemImageName: "checkmark.circle.fill"
            )
        )
        let countdownContent = AlarmPresentation.Countdown(title: "Parking", pauseButton: .pauseButton)
        let pausedContent = AlarmPresentation.Paused(title: "Paused", resumeButton: .resumeButton)
        let attributes = AlarmAttributes<TimerData>(
            presentation: AlarmPresentation(alert: alert, countdown: countdownContent, paused: pausedContent),
            tintColor: .red
        )
      
        // Schedule the alarm as a timer (countdown)
        let alarmID = UUID()
       
        do {
            _ = try await alarmManager.schedule(
                id: alarmID,
                configuration: .timer(
                    duration: duration,
                    attributes: attributes
                )
            )
            currentAlarmID = alarmID
            userMessage = "Timer scheduled."
        } catch {
            userMessage = "Failed to schedule alarm: \(error.localizedDescription)"
        }
    }
}

extension AlarmButton {

    static var pauseButton: Self {
        AlarmButton(text: "Pause", textColor: .black, systemImageName: "pause.fill")
    }
    static var resumeButton: Self {
        AlarmButton(text: "Start", textColor: .black, systemImageName: "play.fill")
    }
}
