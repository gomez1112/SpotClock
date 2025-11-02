//
//  NewTimerView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import MapKit
import SwiftUI

struct NewTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TimerService.self) private var timerManager
    @Environment(LocationService.self) private var locationManager
    @Environment(SubscriptionService.self) private var subscriptionManager
    
    @State private var startTapped = false
    @State private var selectedDuration: TimeInterval = 3600
    @State private var customHours = 1
    @State private var customMinutes = 0
    @State private var notes = ""
    @State private var useCustomDuration = false
    @State private var showSubscription = false
    
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()
                    .opacity(0.2)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Location Card
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
                                        Text("\(location.coordinate.latitude, specifier: "%.4f"), \(location.coordinate.longitude, specifier: "%.4f")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(DesignSystem.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Duration Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Duration", systemImage: "timer")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                        .background(DesignSystem.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Notes (Optional)
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notes (Optional)", systemImage: "note.text")
                                .font(.headline)
                            
                            TextField("e.g., Zone 4B, near coffee shop", text: $notes)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding()
                        .background(DesignSystem.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                }
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        startTapped.toggle()
                        startTimer()
                    }
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
                Task {
                    await locationManager.ensureLocationName()
                }
            }
        }
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
            let name = await locationManager.ensureLocationName()
            let location = locationManager.location
            
            guard location != nil else {
                errorMessage = "Unable to get your location. Please enable location services"
                showErrorAlert = true
                return
            }
            guard let location = locationManager.location else {
                errorMessage = "Unable to get your location. Please enable location services"
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

#Preview {
    NewTimerView()
        .environment(SubscriptionService())
        .environment(TimerService(container: ModelContainerFactory.createPreviewContainer))
        .environment(LocationService())
}
