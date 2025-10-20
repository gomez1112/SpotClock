//
//  AchievementBadge.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import SwiftUI
import UIKit

struct AchievementBadge: View {
    let achievement: Achievement
    @State private var isPressed = false
    @State private var didUnlockAnimation = false
    @State private var ringPulse = false
    @State private var glowPulse = false
    @Namespace private var badgeNamespace
    
    var body: some View {
        VStack(spacing: 16) {
            badgeIconSection
            textContent
            statusIndicator
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background { cardBackground }
        .modifier(CardGlassEffectModifier(achievement: achievement))
        .modifier(CardInteractionModifier(isPressed: $isPressed))
        .onChange(of: achievement.isUnlocked) { _, newValue in
            handleUnlockChange(newValue)
        }
    }
    
    // MARK: - Badge Icon Section
    private var badgeIconSection: some View {
        ZStack {
            mainBadge
            unlockRings
        }
    }
    
    private var mainBadge: some View {
        ZStack {
            badgeCircle
            badgeIcon
        }
    }
    
    private var badgeCircle: some View {
        Circle()
            .fill(achievement.isUnlocked ? achievement.color.gradient : Color.clear.gradient)
            .frame(width: 72, height: 72)
            .overlay { circleOverlay }
            .shadow(
                color: achievement.isUnlocked 
                    ? achievement.color.opacity(0.3)
                    : Color.black.opacity(0.1),
                radius: achievement.isUnlocked ? 8 : 4,
                x: 0,
                y: 2
            )
    }
    
    private var circleOverlay: some View {
        Circle()
            .strokeBorder(strokeGradient, lineWidth: 1.5)
    }
    
    private var strokeGradient: LinearGradient {
        LinearGradient(
            colors: achievement.isUnlocked 
                ? [achievement.color.opacity(0.5), achievement.color.opacity(0.2)]
                : [Color.white.opacity(0.12), Color.white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var badgeIcon: some View {
        Image(systemName: achievement.icon)
            .font(.system(size: 32, weight: .medium, design: .rounded))
            .foregroundStyle(achievement.isUnlocked ? .white : .secondary)
            .shadow(color: achievement.isUnlocked ? Color.black.opacity(0.3) : .clear, radius: 1)
            .symbolEffect(.bounce.up.byLayer, value: didUnlockAnimation)
            .symbolEffect(.pulse.wholeSymbol, options: .repeating, value: achievement.isUnlocked && glowPulse)
    }
    
    private var unlockRings: some View {
        Group {
            if didUnlockAnimation {
                ForEach(0..<3, id: \.self) { index in
                    unlockRing(index: index)
                }
            }
        }
    }
    
    private func unlockRing(index: Int) -> some View {
        Circle()
            .stroke(ringGradient, lineWidth: 2)
            .frame(width: 72, height: 72)
            .scaleEffect(ringPulse ? 1.8 + Double(index) * 0.2 : 0.6)
            .opacity(ringPulse ? 0 : 1.0 - Double(index) * 0.3)
            .animation(
                .easeOut(duration: 1.2)
                .delay(Double(index) * 0.1),
                value: ringPulse
            )
    }
    
    private var ringGradient: LinearGradient {
        LinearGradient(
            colors: [
                achievement.color.opacity(0.8),
                achievement.color.opacity(0.3),
                achievement.color.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Text Content
    private var textContent: some View {
        VStack(spacing: 6) {
            titleText
            descriptionText
        }
        .frame(minHeight: 50)
    }
    
    private var titleText: some View {
        Text(achievement.title)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var descriptionText: some View {
        Text(achievement.description)
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Status Indicator
    private var statusIndicator: some View {
        Group {
            if achievement.isUnlocked {
                unlockedIndicator
            } else {
                lockedIndicator
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: didUnlockAnimation)
    }
    
    private var unlockedIndicator: some View {
        Label {
            Text("Unlocked")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
        } icon: {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption2)
                .symbolEffect(.bounce, value: didUnlockAnimation)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(unlockedBackground)
        .glassEffect(.regular.tint(achievement.color.opacity(0.1)), in: .capsule)
    }
    
    private var unlockedBackground: some View {
        Capsule()
            .fill(achievement.color.gradient)
            .shadow(color: achievement.color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var lockedIndicator: some View {
        Label {
            Text("Locked")
                .font(.system(.caption2, design: .rounded))
        } icon: {
            Image(systemName: "lock.circle.fill")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(.quinary))
        .glassEffect(.regular, in: .capsule)
    }
    
    // MARK: - Card Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(DesignSystem.cardBackground)
            .overlay { cardBorder }
            .shadow(
                color: achievement.isUnlocked 
                    ? achievement.color.opacity(0.2) 
                    : Color.black.opacity(0.05),
                radius: achievement.isUnlocked ? 12 : 6,
                x: 0,
                y: achievement.isUnlocked ? 4 : 2
            )
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(cardBorderGradient, lineWidth: 1)
    }
    
    private var cardBorderGradient: LinearGradient {
        LinearGradient(
            colors: achievement.isUnlocked 
                ? [Color.white.opacity(0.3), Color.white.opacity(0.1)]
                : [Color.white.opacity(0.1), Color.clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - View Extensions
    private var cardGlassEffect: some View {
        modifier(CardGlassEffectModifier(achievement: achievement))
    }
    
    private var cardInteractionEffects: some View {
        modifier(CardInteractionModifier(isPressed: $isPressed))
    }
    
    private func handleUnlockChange(_ newValue: Bool) {
        guard newValue == true else { return }
        
        // Enhanced haptic feedback
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        
        // Start achievement unlock sequence
        didUnlockAnimation = true
        ringPulse = false
        glowPulse = true
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            // triggers bounce via symbolEffect value binding
        }
        
        // Drive the ring expansion with stagger
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            ringPulse = true
        }
        
        // Reset animations after completion
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            didUnlockAnimation = false
            ringPulse = false
        }
    }
}

// MARK: - View Modifiers
private struct CardGlassEffectModifier: ViewModifier {
    let achievement: Achievement
    
    func body(content: Content) -> some View {
        content
            .glassEffect(
                achievement.isUnlocked 
                    ? .regular.tint(achievement.color.opacity(0.1)).interactive() 
                    : .regular,
                in: .rect(cornerRadius: 24)
            )
    }
}

private struct CardInteractionModifier: ViewModifier {
    @Binding var isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1)
            .rotation3DEffect(
                .degrees(isPressed ? 2 : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed.toggle()
                }
                
                // Reset after brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
    }
}

#Preview {
    AchievementBadge(achievement: Achievement(icon: "house", title: "House", description: "This is a house", isUnlocked: false, date: Date(), color: .green))
}
#Preview {
    AchievementBadge(achievement: Achievement(icon: "house", title: "House", description: "This is a house", isUnlocked: true, date: Date(), color: .green))
}
