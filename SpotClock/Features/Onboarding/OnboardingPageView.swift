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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.largeTitle.scaled(by: 2.5))
                    .foregroundStyle(DesignSystem.lavender)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(.largeTitle, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(DesignSystem.screenPadding)
            .appContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize)
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
