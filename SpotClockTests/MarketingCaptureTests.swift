import Foundation
import SwiftData
import Testing
@testable import SpotClock

struct MarketingCaptureTests {
    @MainActor @Test func sampleTimerDoesNotChangeRestorationState() async throws {
        let defaults = UserDefaults.standard
        let sessionID = defaults.string(forKey: "activeSessionID")
        let alarmID = defaults.string(forKey: "activeAlarmID")
        let container = try ModelContainer(for: ParkingSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let timer = TimerService(container: container, restoresSession: false)
        timer.isCaptureSession = true

        await timer.startParking(duration: 3600, location: "Hayes Valley", latitude: 37.7769,
                                 longitude: -122.4241, notes: "Zone 4B")
        let session = try #require(timer.activeSession)
        #expect(timer.isRunning)
        #expect(timer.timeRemaining == 3600)
        #expect(session.notes == "Zone 4B")
        let expiry = session.endTime
        timer.extendParking(by: 900)
        #expect(session.endTime == expiry.addingTimeInterval(900))
        #expect(session.duration == 4500)
        #expect(session.wasExtended)
        timer.updateLeaveNowAlarm(leaveBy: Date.now.addingTimeInterval(60))
        #expect(timer.leaveNowDate == nil)
        timer.stopParking()
        #expect(!timer.isRunning)
        #expect(timer.activeSession == nil)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<ParkingSession>()) == 1)
        #expect(defaults.string(forKey: "activeSessionID") == sessionID)
        #expect(defaults.string(forKey: "activeAlarmID") == alarmID)
    }

    @MainActor @Test func captureUsageIsIndependentOfRealUsage() {
        let before = UserDefaults.standard.data(forKey: "sessionData")
        let subscription = SubscriptionService(persistsUsage: false)
        subscription.recordSession()
        #expect(subscription.hasProAccess)
        #expect(subscription.canStartSession)
        #expect(subscription.monthlySessionsUsed == 1)
        #expect(UserDefaults.standard.data(forKey: "sessionData") == before)
    }
}
