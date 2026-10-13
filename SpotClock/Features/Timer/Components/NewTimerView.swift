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
    @State private var selectedDuration: TimeInterval = 3600
    @State private var customHours = 1
    @State private var customMinutes = 0
    @State private var notes = ""
    @State private var useCustomDuration = false
    @State private var showSubscription = false
    
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isStartingTimer = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Parking Location", systemImage: "location.fill")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(locationManager.locationName)
                                        .font(.subheadline.bold())
                                    
                                    if let location = locationManager.location {
                                        Text(coordinateText(for: location.coordinate))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .appCard(fill: DesignSystem.elevatedCardBackground, cornerRadius: 18)

                        if !smartSuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Label("Smart Suggestions", systemImage: "sparkles")
                                    .font(.headline)

                                Text("Based on your recent parking history around this time.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                VStack(spacing: 10) {
                                    ForEach(smartSuggestions) { suggestion in
                                        Button {
                                            useCustomDuration = false
                                            selectedDuration = suggestion.duration
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: selectedDuration == suggestion.duration && !useCustomDuration ? "checkmark.circle.fill" : "clock.arrow.2.circlepath")
                                                    .foregroundStyle(selectedDuration == suggestion.duration && !useCustomDuration ? .blue : .secondary)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(suggestion.title)
                                                        .font(.subheadline.bold())
                                                        .foregroundStyle(.primary)
                                                    Text(suggestion.detail)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }

                                                Spacer()
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 12)
                                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding()
                            .appCard(fill: DesignSystem.elevatedCardBackground, cornerRadius: 18)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Duration", systemImage: "timer")
                                .font(.headline)
                            
                            LazyVGrid(columns: durationColumns, spacing: 12) {
                                ForEach(DesignSystem.presetDurations, id: \.title) { preset in
                                    DurationButton(
                                        title: preset.title,
                                        icon: preset.icon,
                                        isSelected: !useCustomDuration && selectedDuration == preset.duration
                                    ) {
                                        useCustomDuration = false
                                        selectedDuration = preset.duration
                                    }
                                }
                                
                                DurationButton(
                                    title: "Custom",
                                    icon: "slider.horizontal.3",
                                    isSelected: useCustomDuration
                                ) {
                                    useCustomDuration = true
                                }
                            }
                            
                            if useCustomDuration {
                                HStack(spacing: 20) {
                                    VStack {
                                        Text("Hours")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Picker("Hours", selection: $customHours) {
                                            ForEach(0..<13) { hour in
                                                Text("\(hour)").tag(hour)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 100)
                                    }
                                    
                                    VStack {
                                        Text("Minutes")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Picker("Minutes", selection: $customMinutes) {
                                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                                Text("\(minute)").tag(minute)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 100)
                                    }
                                }
                            }
                        }
                        .padding()
                        .appCard(fill: DesignSystem.elevatedCardBackground, cornerRadius: 18)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notes (Optional)", systemImage: "note.text")
                                .font(.headline)
                            
                            TextField("e.g., Zone 4B, near coffee shop", text: $notes)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding()
                        .appCard(fill: DesignSystem.elevatedCardBackground, cornerRadius: 18)
                    }
                    .padding(DesignSystem.screenPadding)
                    .appContentWidth()
                }
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start", systemImage: "play.fill") {
                        startTapped.toggle()
                        startTimer()
                    }
                    .disabled(isStartingTimer)
                    .sensoryFeedback(.impact(weight: .medium), trigger: startTapped)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .alert("Unable to Start Timer", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                _ = await locationManager.ensureLocationName()
            }
        }
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

#Preview(traits: .previewData) {
    NewTimerView()
}
