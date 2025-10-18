//
//  RingProgressView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//


import SwiftUI

struct RingProgressView: View {
    var progress: Double           // 0...1
    var lineWidth: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(.quaternary, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.accent]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.6), value: progress)
        }
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

#Preview {
    RingProgressView(progress: 0.5, lineWidth: 20)
}
