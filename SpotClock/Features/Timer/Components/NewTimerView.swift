//
//  NewTimerView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import MapKit
import SwiftData
import SwiftUI

struct NewTimerView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.dismiss) private var dismiss
    @Environment(TimerService.self) private var timerManager
    @Environment(LocationService.self) private var locationManager
    @Environment(SubscriptionService.self) private var subscriptionManager
    @Query(sort: \ParkingSession.startTime, order: .reverse) private var sessions: [ParkingSession]
    
    @State private var startTapped = false
    @State private var selectedDuration: TimeInterval
    @State private var customHours = 1
    @State private var customMinutes = 0
    @State private var notes = ""
    @State private var useCustomDuration = false
    @State private var showSubscription = false
    
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isStartingTimer = false
    
    init(initialDuration: TimeInterval = 3600) {
        selectedDuration = initialDuration
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("One last detail.")
                            .font(.system(.title, design: .serif))
                        Text("A duration, a place, and peace of mind.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section("Your parking spot") {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(locationManager.locationName).font(.headline)
                            Text("Saved automatically when you start")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(DesignSystem.brandBlue)
                    }
                }

                Section("How long are you staying?") {
                    LazyVGrid(columns: durationColumns, spacing: 10) {
                        ForEach(DesignSystem.presetDurations, id: \.title) { preset in
                            DurationButton(title: preset.title, icon: preset.icon, isSelected: !useCustomDuration && selectedDuration == preset.duration) {
                                useCustomDuration = false
                                selectedDuration = preset.duration
                            }
                        }
                        DurationButton(title: "Custom", icon: "clock", isSelected: useCustomDuration) {
                            useCustomDuration = true
                        }
                    }
                    .padding(.vertical, 8)
                    if useCustomDuration {
                        Picker("Hours", selection: $customHours) {
                            ForEach(0..<13) { Text("\($0) hours").tag($0) }
                        }
                        Picker("Minutes", selection: $customMinutes) {
                            ForEach(0..<12) { Text("\($0 * 5) minutes").tag($0 * 5) }
                        }
                    }
                }

                if !smartSuggestions.isEmpty {
                    Section("Your usual stay") {
                        ForEach(smartSuggestions) { suggestion in
                            Button {
                                useCustomDuration = false
                                selectedDuration = suggestion.duration
                            } label: {
                                LabeledContent {
                                    Image(systemName: "sparkles")
                                } label: {
                                    Text(suggestion.title).font(.subheadline.bold())
                                    Text(suggestion.detail).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section {
                    TextField("Level 2, near the elevator…", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("A note for later")
                } footer: {
                    Label("We’ll keep an eye on the clock.", systemImage: "bell.badge.fill")
                }
            }
            .scrollContentBackground(.hidden)
            .background { AppBackground() }
            .navigationTitle("New parking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start timer", systemImage: "play.fill") {
                        startTapped.toggle()
                        startTimer()
                    }
                    .accessibilityIdentifier("parking.confirm")
                    .disabled(isStartingTimer)
                    .sensoryFeedback(.impact(weight: .medium), trigger: startTapped)
                }
            }
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
            .alert("Unable to Start Timer", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage) }
            .task { _ = await locationManager.ensureLocationName() }
        }
        .tint(DesignSystem.brandBlue)
    }

    private var smartSuggestions: [ParkingDurationSuggestion] {
        ParkingRecommendationEngine.suggestions(from: sessions)
    }

    private var durationColumns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
    }

    private func coordinateText(for coordinate: CLLocationCoordinate2D) -> String {
        let latitude = coordinate.latitude.formatted(.number.precision(.fractionLength(4)))
        let longitude = coordinate.longitude.formatted(.number.precision(.fractionLength(4)))
        return "\(latitude), \(longitude)"
    }
    
    private func startTimer() {
        // ✅ FIXED: Re-check subscription status before starting the timer.
        guard subscriptionManager.canStartSession else {
            // If the user can't start a session, show the paywall and stop.
            showSubscription = true
            return
        }
        let duration = useCustomDuration
        ? TimeInterval(customHours * 3600 + customMinutes * 60)
        : selectedDuration
        guard duration > 0 else {
            errorMessage = "Please select a duration greater than 0."
            showErrorAlert = true
            return
        }
        
        Task { @MainActor in
            isStartingTimer = true
            defer { isStartingTimer = false }

            let name = await locationManager.ensureLocationName()

            guard let location = locationManager.location else {
                errorMessage = locationManager.errorMessage ?? "Unable to get your location. Please enable location services."
                showErrorAlert = true
                return
            }

            await timerManager.startParking(
                duration: duration,
                location: name,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                notes: notes
            )
            if timerManager.isRunning {
                subscriptionManager.recordSession()
                dismiss()
            } else {
                errorMessage = timerManager.userMessage ?? "Failed to start timer. Please try again."
                showErrorAlert = true
            }

        }
    }
}
