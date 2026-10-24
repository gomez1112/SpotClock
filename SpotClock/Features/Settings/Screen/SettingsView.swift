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
    @State private var showCaptureStudio = false
    @Environment(\.isMarketingCapture) private var isMarketingCapture
    @Environment(\.dismiss) private var dismiss
    #endif
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "parkingsign")
                            .font(.title.bold()).foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(DesignSystem.primaryGradient, in: .rect(cornerRadius: 20))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("A considered companion.").font(.system(.title3, design: .serif))
                            Text("SpotClock · Designed for your day.").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .listRowBackground(Color.clear)
                Section("Your membership") { subscriptionSection }
                Section("Make it yours") {
                    Button {
                        Task { await subscriptionManager.restorePurchases() }
                    } label: { Label("Restore purchases", systemImage: "arrow.clockwise") }
                    .disabled(!allowsServiceActions)
                    Button { requestNotificationPermission() } label: {
                        Label("Enable parking alarms", systemImage: "bell.badge.fill")
                    }
                    .disabled(!allowsServiceActions)
                }
                Section("About SpotClock") {
                    LabeledContent("Version", value: getAppVersionAndBuild.version ?? "2.0.0")
                    Link("Privacy policy", destination: privacyPolicyURL)
                    Link("Terms of service", destination: termsURL)
                }
                #if DEBUG
                Section("Development") {
                    if isMarketingCapture {
                        Button("Exit capture studio", systemImage: "xmark") { dismiss() }
                    } else {
                        Button("Open marketing capture studio", systemImage: "sparkles") { showCaptureStudio = true }
                    }
                    if !isMarketingCapture { developerToolsSection }
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .background { AppBackground() }
            .navigationTitle("Settings")
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
            #if DEBUG
            .fullScreenCover(isPresented: $showCaptureStudio) { MarketingCaptureStudioView() }
            #endif
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: { Text(alertMessage) }
        }
        .tint(DesignSystem.brandBlue)
    }

    private var allowsServiceActions: Bool {
        #if DEBUG
        !isMarketingCapture
        #else
        true
        #endif
    }

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppSectionHeader(title: "Subscription", systemImage: "crown.fill", tint: DesignSystem.warmAccent)

            if subscriptionManager.hasProAccess {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pro Member")
                            .font(.headline)
                        Text("Unlimited timers are active.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            } else {
                Button {
                    showSubscription = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundStyle(DesignSystem.warmAccent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upgrade to Pro")
                                .font(.headline)
                            Text("\(subscriptionManager.sessionsRemaining) free timers left this month")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "Actions", systemImage: "slider.horizontal.3", tint: DesignSystem.brandBlue)

            Button {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            } label: {
                settingsRow(title: "Restore Purchases", subtitle: "Recover an active App Store subscription.", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                requestNotificationPermission()
            } label: {
                settingsRow(title: "Enable Alarms", subtitle: "Allow full-screen parking timer alerts.", systemImage: "alarm")
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .appCard(fill: DesignSystem.elevatedCardBackground)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "About", systemImage: "info.circle.fill", tint: DesignSystem.brandTeal)

            HStack {
                settingsRow(title: "Version", subtitle: getAppVersionAndBuild.version ?? "Unknown", systemImage: "number")
                Spacer()
            }

            Divider()

            Link(destination: privacyPolicyURL) {
                settingsRow(title: "Privacy Policy", subtitle: "How SpotClock handles app data.", systemImage: "hand.raised")
            }
            .buttonStyle(.plain)

            Divider()

            Link(destination: termsURL) {
                settingsRow(title: "Terms of Service", subtitle: "Apple standard end user license agreement.", systemImage: "doc.text")
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .appCard(fill: DesignSystem.elevatedCardBackground)
    }

    private func settingsRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(DesignSystem.brandBlue)
                .frame(width: 36, height: 36)
                .background(DesignSystem.brandBlue.opacity(0.1), in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(.rect)
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
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "Developer Tools", systemImage: "hammer.fill", tint: DesignSystem.brandIndigo)

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

            Text("Debug builds only. Generated sessions are tracked separately so clearing them won’t delete your real history.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .appCard(fill: DesignSystem.elevatedCardBackground)
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

    private var privacyPolicyURL: URL {
        URL(string: "https://transfinite.us/policies/") ?? URL(filePath: "/")
    }

    private var termsURL: URL {
        URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") ?? URL(filePath: "/")
    }
}
