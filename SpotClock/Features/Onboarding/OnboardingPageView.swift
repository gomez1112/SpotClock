//
//  OnboardingPageView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import SwiftUI

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.white.opacity(animate ? 0.2 : 0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .scaleEffect(animate ? 1.2 : 0.9)
                
                Image(systemName: icon)
                    .font(.system(size: 90, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    .scaleEffect(animate ? 1 : 0.9)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
            
            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                
                Text(description)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
        .appContentWidth()
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(color)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(color.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    OnboardingPageView(icon: "house", title: "House", description: "I love this house", accentColor: .accentColor)
        .environment(LocationService())
}
