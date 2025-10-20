//
//  TimerManager.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import os
import Foundation
@preconcurrency import AlarmKit
import SwiftData
import SwiftUI

nonisolated struct TimerData: AlarmMetadata {
    let parkingTitle: String
    let location: String
}

@Observable
final class TimerService {
    private let logger = Logger(subsystem: "com.transfinite.SpotClock", category: "TimerManager")
    private var hasExpired = false
    @ObservationIgnored private let alarmManager = AlarmManager.shared
    private let modelContext: ModelContext
    
    // Public properties for views
    var activeSession: ParkingSession?
    var timeRemaining: TimeInterval = 0
    var isRunning = false
    var userMessage: String?
    
    // Private properties
    private var tickTimer: Timer?
    private var currentAlarmID: UUID?
    
    private var leaveNowAlarmID: UUID?
    var leaveNowDate: Date?
    
    init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
        Task {
            // ✅ FIXED: Call the new, safer state restoration function instead of the old cleanup.
            await cleanupPendingAlarm()
        }
    }

    func startParking(
        duration: TimeInterval,
        location: String,
        latitude: Double,
        longitude: Double,
        notes: String = ""
    ) async {
        hasExpired = false
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
    }
    
    func stopParking() {
        // Capture the session before it's cleared
        if let sessionToSave = activeSession {
            modelContext.insert(sessionToSave)
            // It's good practice to try saving immediately
            try? modelContext.save()
        }
        
        let alarmID = currentAlarmID
        currentAlarmID = nil
        
        isRunning = false
        timeRemaining = 0
        activeSession = nil
        tickTimer?.invalidate()
        tickTimer = nil
        
        if let alarmID {
            Task {
                try? alarmManager.cancel(id: alarmID)
                UserDefaults.standard.removeObject(forKey: "activeAlarmID")
            }
        }
        if let leaveID = leaveNowAlarmID {
            Task {
                try? alarmManager.cancel(id: leaveID)
                leaveNowAlarmID = nil
                leaveNowDate = nil
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    func extendParking(by additionalTime: TimeInterval) {
        guard let session = activeSession else { return }
        
        session.endTime = session.endTime.addingTimeInterval(additionalTime)
        session.duration += additionalTime
        session.wasExtended = true
        
        // Stop current timer
        tickTimer?.invalidate()
        tickTimer = nil
        
        Task {
            if let alarmID = currentAlarmID {
                try? alarmManager.cancel(id: alarmID)
            }
            await scheduleTimer(for: session)
            
            if let leaveDate = leaveNowDate {
                await scheduleLeaveNowAlarm(at: leaveDate, session: session)
            }
            // Restart timer
            await MainActor.run {
                startTicking()
            }
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    func updateLeaveNowAlarm(leaveBy: Date?) {
        Task {
            guard let session = activeSession else { return }
            // Cancel previous leave-alarm if any
            if let existing = leaveNowAlarmID {
                try? alarmManager.cancel(id: existing)
                leaveNowAlarmID = nil
            }
            
            leaveNowDate = leaveBy
            
            guard let leaveBy, leaveBy > Date() else { return }
            await scheduleLeaveNowAlarm(at: leaveBy, session: session)
        }
    }
    // MARK: - Private Methods
    
    private func startTicking() {
        if currentAlarmID == nil {
            userMessage = "Warning: Alarm not scheduled, but timer will run."
        }
        
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateRemaining()
            }
        }
        
        if let timer = tickTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func updateRemaining() {
        guard let session = activeSession else { return }
        let remaining = max(0, session.endTime.timeIntervalSinceNow)
        timeRemaining = remaining
        
        if remaining <= 0 && !hasExpired {
            hasExpired = true
            isRunning = false
            tickTimer?.invalidate()
            modelContext.insert(session)
            try? modelContext.save()
            activeSession = nil
            UserDefaults.standard.removeObject(forKey: "activeAlarmID")
            if let leaveID = leaveNowAlarmID {
                Task {
                    try? alarmManager.cancel(id: leaveID)
                }
                leaveNowAlarmID = nil
                leaveNowDate = nil
            }
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
            title: "🚨 Parking Expired! • \(session.location)",
            stopButton: AlarmButton(
                text: "Dismiss",
                textColor: .white,
                systemImageName: "checkmark.circle.fill"
            )
        )
        let metadata = TimerData(
            parkingTitle: "Parking",
            location: session.location
        )
        let countdownContent = AlarmPresentation.Countdown(title: "Parking", pauseButton: .pauseButton)
        let pausedContent = AlarmPresentation.Paused(title: "Paused", resumeButton: .resumeButton)
        let attributes = AlarmAttributes<TimerData>(
            presentation: AlarmPresentation(alert: alert, countdown: countdownContent, paused: pausedContent),
            metadata: metadata, tintColor: .indigo
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
            UserDefaults.standard.set(alarmID.uuidString, forKey: "activeAlarmID")
            userMessage = "Timer scheduled."
        } catch {
            userMessage = "Failed to schedule alarm: \(error.localizedDescription)"
            logger.error("Failed to schedule alarm: \(error.localizedDescription)")
        }
    }
    // MARK: - NEW: schedule leave-now alarm
    private func scheduleLeaveNowAlarm(at date: Date, session: ParkingSession) async {
        let duration = date.timeIntervalSinceNow
        guard duration > 0 else { return }
        
        let alert = AlarmPresentation.Alert(
            title: "🚶 Time to head back • \(session.location)",
            stopButton: AlarmButton(
                text: "OK",
                textColor: .white,
                systemImageName: "checkmark.circle.fill"
            )
        )
        let attributes = AlarmAttributes<TimerData>(
            presentation: AlarmPresentation(
                alert: alert,
                countdown: AlarmPresentation.Countdown(title: "Leave Soon", pauseButton: .pauseButton),
                paused: AlarmPresentation.Paused(title: "Paused", resumeButton: .resumeButton)
            ),
            metadata: TimerData(parkingTitle: "LeaveNow", location: session.location),
            tintColor: .indigo
        )
        
        let id = UUID()
        do {
            _ = try await alarmManager.schedule(
                id: id,
                configuration: .timer(duration: duration, attributes: attributes)
            )
            leaveNowAlarmID = id
        } catch {
            logger.error("LeaveNow schedule failed: \(error.localizedDescription)")
        }
    }
    // MARK: - Alarm Cleanup on Launch
    private func cleanupPendingAlarm() async {
        if let stored = UserDefaults.standard.string(forKey: "activeAlarmID"),
           let uuid = UUID(uuidString: stored) {
            do {
                try alarmManager.cancel(id: uuid)
                logger.notice("Cleaned up stale alarm \(uuid)")
                UserDefaults.standard.removeObject(forKey: "activeAlarmID")
            } catch {
                logger.error("Cleanup failed: \(error.localizedDescription)")
            }
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
