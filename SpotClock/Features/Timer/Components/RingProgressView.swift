//
//  RingProgressView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//


import SwiftUI

struct RingProgressView: View {
    var lineWidth: CGFloat = 20
    @Environment(TimerService.self) private var timerManager
    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 24)
                .frame(width: 240, height: 240)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timeGradient,
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: timerManager.timeRemaining)
            // Inner content
            VStack {
                Image(systemName: "parkingsign.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tertiary)
                
                Text("\(Int(progress * 100))%")
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .shadow(color: timeColor.opacity(0.2), radius: 20, y: 10)
        .padding()
    }
    private var timeColor: Color {
        if timerManager.timeRemaining > 600 { return .green }
        else if timerManager.timeRemaining > 300 { return .orange }
        else { return .red }
    }
    
    private var timeGradient: LinearGradient {
        if timerManager.timeRemaining > 600 {
            return LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if timerManager.timeRemaining > 300 {
            return LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.red, .red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    private var progress: Double {
        guard let session = timerManager.activeSession, session.duration > 0 else { return 0 }
        return timerManager.timeRemaining / session.duration
    }
}

#Preview(traits: .previewData) {
    RingProgressView(lineWidth: 20)
}
