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
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.smooth(duration: 0.6), value: currentPage)
            
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    icon: "car.fill",
                    title: "Never Get a\nParking Ticket",
                    description: "Set timers for your parking meter and get notified before it expires.",
                    accentColor: .blue
                )
                .tag(0)
                
                OnboardingPageView(
                    icon: "bell.badge.fill",
                    title: "Smart Alerts",
                    description: "Receive notifications 10 and 5 minutes before your meter expires.",
                    accentColor: .orange
                )
                .tag(1)
                
                OnboardingPageView(
                    icon: "map.fill",
                    title: "Never Forget\nWhere You Parked",
                    description: "Automatically saves your parking location with every timer.",
                    accentColor: .purple
                )
                .tag(2)
                
                permissionsPage
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            VStack {
                HStack {
                    Spacer()
                    
                    if currentPage < 3 {
                        Button("Skip") {
                            withAnimation {
                                currentPage = 3
                            }
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                }
                
                Spacer()
                
                // Custom page indicator
                if currentPage < 3 {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                                .frame(width: currentPage == index ? 24 : 8, height: 8)
                                .animation(.smooth, value: currentPage)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(backgroundColors[0])
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showNotificationToast {
                ToastBanner(text: notificationToastText, color: notificationToastColor)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
    }
    
    private var backgroundColors: [Color] {
        switch currentPage {
            case 0: return [.blue, .blue.opacity(0.7)]
            case 1: return [.orange, .orange.opacity(0.7)]
            case 2: return [.purple, .purple.opacity(0.7)]
            default: return [.green, .green.opacity(0.7)]
        }
    }
    
    private var permissionsPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .blur(radius: 30)
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 90, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            }
            
            VStack(spacing: 16) {
                Text("Enable Permissions")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("SpotClock needs a few permissions\nto work its magic")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
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
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button {
                requestPermissions()
            } label: {
                Text("Enable & Get Started")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.3)) { showNotificationToast = false }
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    withAnimation { isPresented = false }
                }
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

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environment(LocationService())
}
