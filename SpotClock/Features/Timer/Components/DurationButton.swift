//
//  DurationButton.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import SwiftUI

struct DurationButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? DesignSystem.primaryGradient : LinearGradient(colors: [DesignSystem.cardBackground], startPoint: .leading, endPoint: .trailing))
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? .clear : DesignSystem.cardStroke(), lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DurationButton(title: "No title", icon: "house", isSelected: true, action: {})
}
