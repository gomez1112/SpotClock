//
//  AppIntent.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/18/25.
//


import AlarmKit
import AppIntents

// ✅ FIXED: Replaced force-unwrapping with safe `guard let` statements in all intents.

struct PauseIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }
        try AlarmManager.shared.pause(id: uuid)
        return .result()
    }
    
    static let title: LocalizedStringResource = "Pause"
    static let description = IntentDescription("Pause a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

struct StopIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }
        try AlarmManager.shared.stop(id: uuid)
        return .result()
    }
    
    static let title: LocalizedStringResource = "Stop"
    static let description = IntentDescription("Stop an alert")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

struct RepeatIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }
        try AlarmManager.shared.countdown(id: uuid)
        return .result()
    }
    
    static let title: LocalizedStringResource = "Repeat"
    static let description = IntentDescription("Repeat a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

struct ResumeIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }
        try AlarmManager.shared.resume(id: uuid)
        return .result()
    }
    
    static let title: LocalizedStringResource = "Resume"
    static let description = IntentDescription("Resume a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

struct OpenAlarmAppIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }
        try AlarmManager.shared.stop(id: uuid)
        return .result()
    }
    
    static let title: LocalizedStringResource = "Open App"
    static let description = IntentDescription("Opens the Sample app")
    static let openAppWhenRun = true
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}
