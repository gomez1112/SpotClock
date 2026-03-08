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


@MainActor
@Observable
final class TimerService {
    private let logger = Logger(subsystem: "com.transfinite.SpotClock", category: "TimerManager")
    private var hasExpired = false
    @ObservationIgnored private let alarmManager = AlarmManager.shared
    private let container: ModelContainer
    private let modelContext: ModelContext
    private var didEnterBackgroundDate: Date?
    
    // Public properties for views
    var activeSession: ParkingSession?
    var timeRemaining: TimeInterval = 0
    var isRunning = false
    var userMessage: String?
    
    // Private properties
    private var leaveAlarmUpdateTask: Task<Void, Never>?
    private var tickTimer: Timer?
    private var currentAlarmID: UUID?
    
    private var leaveNowAlarmID: UUID?
    var leaveNowDate: Date?
    
    init(container: ModelContainer) {
        self.container = container
        self.modelContext = ModelContext(container)
        
        Task {
            // ✅ FIXED: Restore state BEFORE cleanup
            await restoreActiveSession()
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
        // ✅ FIXED: Cancel any existing leave-now alarm before starting a new session
        if let existingLeaveAlarm = leaveNowAlarmID {
            try? alarmManager.cancel(id: existingLeaveAlarm)
            leaveNowAlarmID = nil
            leaveNowDate = nil
            logger.notice("Cancelled existing leave-now alarm before starting new session")
        }
        
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
        
        // Require alarm authorization before creating a persistent session.
        guard await checkForAuthorization() else {
            userMessage = "Alarm permission required. Enable in Settings."
            return
        }
        
        // ✅ FIXED: Save session to database immediately so it persists across app kills
        modelContext.insert(session)
        do {
            try modelContext.save()
            
            // Store the session ID in UserDefaults for restoration
            UserDefaults.standard.set(session.id.uuidString, forKey: "activeSessionID")
            
            activeSession = session
            timeRemaining = duration
            isRunning = true
            
            // Schedule the alarm
            await scheduleTimer(for: session)
            
            // Start UI ticker
            startTicking()
        } catch {
            logger.error("Failed to save session: \(error.localizedDescription)")
            userMessage = "Failed to save parking session."
        }
    }
    
    func stopParking() {
        // ✅ FIXED: Record actual end time and persist.
        if let session = activeSession {
            session.endTime = Date()
            session.duration = max(0, session.endTime.timeIntervalSince(session.startTime))
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
        // ✅ FIXED: Also remove the session ID
        UserDefaults.standard.removeObject(forKey: "activeSessionID")
        
        // ✅ FIXED: Always cancel leave-now alarm when stopping
        if let leaveID = leaveNowAlarmID {
            Task {
                try? alarmManager.cancel(id: leaveID)
                logger.notice("Cancelled leave-now alarm on stop parking")
            }
            leaveNowAlarmID = nil
            leaveNowDate = nil
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    func extendParking(by additionalTime: TimeInterval) {
        guard let session = activeSession else { return }
        
        session.endTime = session.endTime.addingTimeInterval(additionalTime)
        session.duration += additionalTime
        session.wasExtended = true
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save extended session: \(error.localizedDescription)")
        }
        
        // Stop current timer
        tickTimer?.invalidate()
        tickTimer = nil
        
        Task {
            if let alarmID = currentAlarmID {
                try? alarmManager.cancel(id: alarmID)
            }
            
            // ✅ FIXED: Cancel old leave-now alarm before rescheduling
            if let leaveID = leaveNowAlarmID {
                try? alarmManager.cancel(id: leaveID)
                leaveNowAlarmID = nil
                logger.notice("Cancelled old leave-now alarm during extension")
            }
            
            await scheduleTimer(for: session)
            
            // ✅ FIXED: Reset leave-now date so it recalculates with new expiry time
            leaveNowDate = nil
            
            // Restart timer
            await MainActor.run {
                startTicking()
            }
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func updateLeaveNowAlarm(leaveBy: Date?) {
        // Cancel any pending update task
        leaveAlarmUpdateTask?.cancel()
        
        // Create a new task with a small delay to debounce rapid calls
        leaveAlarmUpdateTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            // Small delay to debounce multiple rapid calls
            try? await Task.sleep(for: .milliseconds(100))
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            guard let session = self.activeSession else { return }
            
            // Cancel previous leave-alarm if any
            if let existing = self.leaveNowAlarmID {
                try? self.alarmManager.cancel(id: existing)
                self.leaveNowAlarmID = nil
                self.logger.notice("Cancelled previous leave-now alarm before scheduling new one")
            }
            
            self.leaveNowDate = leaveBy
            
            guard let leaveBy, leaveBy > Date() else { return }
            await self.scheduleLeaveNowAlarm(at: leaveBy, session: session)
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
            
            // ✅ FIXED: Session already in database, just save updates
            do {
                try modelContext.save()
                logger.notice("Session saved successfully on expiration")
            } catch {
                logger.error("Failed to save expired session: \(error.localizedDescription)")
            }
            
            activeSession = nil
            UserDefaults.standard.removeObject(forKey: "activeAlarmID")
            UserDefaults.standard.removeObject(forKey: "activeSessionID")
            
            // ✅ FIXED: Cancel leave-now alarm when session expires
            if let leaveID = leaveNowAlarmID {
                Task {
                    try? alarmManager.cancel(id: leaveID)
                    logger.notice("Cancelled leave-now alarm on session expiration")
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
            logger.notice("Scheduled main parking alarm: \(alarmID)")
        } catch {
            userMessage = "Failed to schedule alarm: \(error.localizedDescription)"
            logger.error("Failed to schedule alarm: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Schedule leave-now alarm
    private func scheduleLeaveNowAlarm(at date: Date, session: ParkingSession) async {
        let duration = date.timeIntervalSinceNow
        guard duration > 0 else {
            logger.notice("Leave-by time is in the past, not scheduling")
            return
        }
        
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
            logger.notice("Scheduled leave-now alarm: \(id) for \(duration)s from now")
        } catch {
            logger.error("LeaveNow schedule failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Alarm Cleanup on Launch
    private func cleanupPendingAlarm() async {
        // Only clean up if we don't have a valid active session restored.
        guard activeSession == nil else { return }
        if let stored = UserDefaults.standard.string(forKey: "activeAlarmID"),
           let uuid = UUID(uuidString: stored) {
            do {
                try alarmManager.cancel(id: uuid)
                logger.notice("Cleaned up stale parking alarm: \(uuid)")
                UserDefaults.standard.removeObject(forKey: "activeAlarmID")
            } catch {
                logger.error("Cleanup failed: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor private func restoreActiveSession() async {
        // ✅ FIXED: Use session ID instead of alarm ID for more reliable restoration
        guard let storedSessionID = UserDefaults.standard.string(forKey: "activeSessionID"),
              let sessionUUID = UUID(uuidString: storedSessionID) else {
            // Clean up stale alarm ID if no session ID exists
            UserDefaults.standard.removeObject(forKey: "activeAlarmID")
            return
        }
        
        // Also get the alarm ID if it exists
        let alarmID = UserDefaults.standard.string(forKey: "activeAlarmID").flatMap { UUID(uuidString: $0) }
        
        // Fetch the specific session by ID
        let descriptor = FetchDescriptor<ParkingSession>(
            predicate: #Predicate<ParkingSession> { session in
                session.id == sessionUUID
            }
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            
            if let session = sessions.first {
                // Check if session is still active
                if session.isActive {
                    self.activeSession = session
                    self.timeRemaining = session.timeRemaining
                    self.isRunning = true
                    self.currentAlarmID = alarmID

                    if alarmID == nil {
                        logger.notice("Restored session without alarm ID. Scheduling a replacement alarm.")
                        await scheduleTimer(for: session)
                    }

                    self.startTicking()
                    
                    logger.notice("Restored active session: \(session.id)")
                } else {
                    // Session expired while app was closed
                    logger.notice("Session expired while app was closed")
                    UserDefaults.standard.removeObject(forKey: "activeAlarmID")
                    UserDefaults.standard.removeObject(forKey: "activeSessionID")
                }
            } else {
                // Session not found in database
                logger.warning("Session \(sessionUUID) not found in database")
                UserDefaults.standard.removeObject(forKey: "activeAlarmID")
                UserDefaults.standard.removeObject(forKey: "activeSessionID")
            }
        } catch {
            logger.error("Failed to restore session: \(error.localizedDescription)")
            // Clean up on error
            UserDefaults.standard.removeObject(forKey: "activeAlarmID")
            UserDefaults.standard.removeObject(forKey: "activeSessionID")
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
