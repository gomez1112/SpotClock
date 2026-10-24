//
//  OnboardingView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import SwiftUI
import AlarmKit

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Environment(LocationService.self) private var locationManager
    @State private var currentPage = 0
    @State private var animateContent = false
    @State private var showNotificationToast = false
    @State private var notificationToastText = ""
    @State private var notificationToastColor: Color = .green
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    icon: "car.fill",
                    title: "Time, on your side.",
                    description: "Set your parking timer and go enjoy the good part of your day.",
                    accentColor: .blue
                )
                .tag(0)

                OnboardingPageView(
                    icon: "bell.badge.fill",
                    title: "A little heads-up.",
                    description: "Timely parking alerts help you return before your meter expires.",
                    accentColor: .orange
                )
                .tag(1)

                OnboardingPageView(
                    icon: "map.fill",
                    title: "Your way back,\nsorted.",
                    description: "Your spot is saved with every timer. Walking directions take you right back.",
                    accentColor: .purple
                )
                .tag(2)

                permissionsPage
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .safeAreaInset(edge: .bottom) {
                onboardingControls
            }
            .background {
                LinearGradient(
                    colors: backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .animation(reduceMotion ? nil : .smooth, value: currentPage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if currentPage < 3 {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Skip", systemImage: "arrow.forward") {
                            currentPage = 3
                        }
                    }
                }
            }
            .tint(.white)
            .overlay(alignment: .bottom) {
                if showNotificationToast {
                    ToastBanner(text: notificationToastText, color: notificationToastColor)
                        .padding()
                        .transition(.opacity)
                }
            }
        }
    }

    private var onboardingControls: some View {
        VStack(spacing: 16) {
            if currentPage < 3 {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Introduction")
                .accessibilityValue("Page \(currentPage + 1) of 3")
            }

            Button {
                if currentPage < 3 {
                    currentPage += 1
                } else {
                    requestPermissions()
                }
            } label: {
                Text(currentPage < 3 ? "Continue" : "Enable & Get Started")
                    .font(.headline)
                    .foregroundStyle(DesignSystem.brandBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white, in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.screenPadding)
        .appContentWidth()
    }

    private var backgroundColors: [Color] {
        switch currentPage {
            case 0: return [DesignSystem.ink, DesignSystem.brandIndigo]
            case 1: return [DesignSystem.ink, DesignSystem.brandIndigo]
            case 2: return [DesignSystem.ink, DesignSystem.brandIndigo]
            default: return [DesignSystem.ink, DesignSystem.brandIndigo]
        }
    }
    
    private var permissionsPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.largeTitle.scaled(by: 2))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)

                Text("Enable Permissions")
                    .font(.system(.largeTitle, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("SpotClock needs a few permissions to save your spot and alert you on time.")
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                PermissionCard(
                    icon: "bell.fill",
                    title: "Alarms",
                    description: "Get timely alerts before your meter expires",
                    color: .white
                )

                PermissionCard(
                    icon: "location.fill",
                    title: "Location",
                    description: "Automatically save your parking spot",
                    color: .white
                )
            }
            .padding(DesignSystem.screenPadding)
            .appContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func requestPermissions() {
        Task { @MainActor in
            do {
                let state = try await AlarmManager.shared.requestAuthorization()
                if state == .authorized {
                    notificationToastText = "Alarms enabled"
                    notificationToastColor = .green
                } else {
                    notificationToastText = "Alarms disabled"
                    notificationToastColor = .red
                }
                withAnimation(.spring(duration: 0.35)) { showNotificationToast = true }
                
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.easeInOut(duration: 0.3)) {
                    showNotificationToast = false
                }
                try? await Task.sleep(for: .milliseconds(100))
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                
                UserDefaults.standard.synchronize()
                
                withAnimation { isPresented = false }
            } catch {
                notificationToastText = "Alarms permission error"
                notificationToastColor = .red
                withAnimation(.spring(duration: 0.35)) { showNotificationToast = true }
            }
        }
        
        // Location stays the same
        locationManager.requestPermission()
    }
}

private struct ToastBanner: View {
    let text: String
    let color: Color
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(color)
            Text(text)
                .foregroundStyle(.primary)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
    }
}
