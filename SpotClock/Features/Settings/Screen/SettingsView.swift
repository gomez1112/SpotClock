//
//  SettingsView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//


import SwiftData
import SwiftUI
import StoreKit
import AlarmKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionManager
    @State private var showSubscription = false
    @State private var showAlert = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    #if DEBUG
    @State private var isRunningDeveloperAction = false
    #endif
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if subscriptionManager.hasProAccess {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                            Text("Pro Member")
                                .font(.headline)
                            Spacer()
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    } else {
                        Button {
                            showSubscription = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Upgrade to Pro")
                                        .font(.headline)
                                    Text("Unlimited parking timers")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                } header: {
                    Text("Subscription")
                } footer: {
                    if !subscriptionManager.hasProAccess {
                        Text("Free: \(subscriptionManager.sessionsRemaining) timers left this month")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        if let version = getAppVersionAndBuild.version {
                            Text(version)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://transfinite.us/policies/")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                    
                    Button(role: .destructive) {
                        requestNotificationPermission()
                    } label: {
                        Label("Enable Alarms", systemImage: "alarm")
                    }

                }

                #if DEBUG
                developerToolsSection
                #endif
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func requestNotificationPermission() {
        Task { @MainActor in
            do {
                let state = try await AlarmManager.shared.requestAuthorization()
                if state == .authorized {
                    alertTitle = "Alarms Enabled"
                    alertMessage = "You’ll get AlarmKit alerts for your parking timers."
                } else {
                    alertTitle = "Alarms Disabled"
                    alertMessage = "Go to Settings > SpotClock > Alarms and allow access."
                }
                showAlert = true
            } catch {
                alertTitle = "Error"
                alertMessage = "Could not request Alarm permission: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    #if DEBUG
    private var developerToolsSection: some View {
        Section {
            LabeledContent("Generated Sessions") {
                Text("\(DebugSampleDataSeeder.generatedSessionCount)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Button {
                runDeveloperAction {
                    let inserted = try DebugSampleDataSeeder.generateSessions(count: 30, into: modelContext)
                    alertTitle = "Sample Data Added"
                    alertMessage = "Inserted \(inserted) sample sessions."
                }
            } label: {
                Label("Generate 30 Sample Sessions", systemImage: "tray.and.arrow.down")
            }
            .disabled(isRunningDeveloperAction)

            Button {
                runDeveloperAction {
                    let inserted = try DebugSampleDataSeeder.generateSessions(count: 100, into: modelContext)
                    alertTitle = "Sample Data Added"
                    alertMessage = "Inserted \(inserted) sample sessions."
                }
            } label: {
                Label("Generate 100 Sample Sessions", systemImage: "shippingbox")
            }
            .disabled(isRunningDeveloperAction)

            Button {
                runDeveloperAction {
                    let inserted = try DebugSampleDataSeeder.generateSessions(count: 500, into: modelContext)
                    alertTitle = "Sample Data Added"
                    alertMessage = "Inserted \(inserted) sample sessions."
                }
            } label: {
                Label("Generate 500 Sample Sessions", systemImage: "externaldrive.badge.plus")
            }
            .disabled(isRunningDeveloperAction)

            Button(role: .destructive) {
                runDeveloperAction {
                    let removed = try DebugSampleDataSeeder.clearGeneratedSessions(from: modelContext)
                    alertTitle = "Sample Data Cleared"
                    alertMessage = removed == 0
                        ? "There were no generated sessions to remove."
                        : "Removed \(removed) generated sessions."
                }
            } label: {
                Label("Clear Sample Data", systemImage: "trash")
            }
            .disabled(isRunningDeveloperAction)
        } header: {
            Text("Developer Tools")
        } footer: {
            Text("Debug builds only. Generated sessions are tracked separately so clearing them won’t delete your real history.")
        }
    }

    private func runDeveloperAction(_ action: @escaping @MainActor () throws -> Void) {
        Task { @MainActor in
            guard !isRunningDeveloperAction else { return }
            isRunningDeveloperAction = true
            defer { isRunningDeveloperAction = false }

            do {
                try action()
            } catch {
                alertTitle = "Developer Action Failed"
                alertMessage = error.localizedDescription
            }

            showAlert = true
        }
    }
    #endif

    var getAppVersionAndBuild: (version: String?, build: String?) {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String
        return (version, build)
    }
}

#Preview {
    SettingsView()
        .environment(SubscriptionService())
}
