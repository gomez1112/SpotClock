//
//  DualRingView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import SwiftUI

struct DualRingView: View {
    let outerProgress: CGFloat
    let innerProgress: CGFloat
    
    var body: some View {
        ZStack {
            RingProgressView()
            Circle()
                .inset(by: 35)
                .trim(from: 0, to: max(0, innerProgress))
                .stroke(LinearGradient(colors: [.indigo, .indigo.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: .indigo.opacity(0.25), radius: 8, y: 4)
                .animation(.smooth(duration: 0.35), value: innerProgress)
        }
        .frame(width: 240, height: 240)
    }
}

#Preview(traits: .previewData) {
    DualRingView(outerProgress: 0.4, innerProgress: 0.8)
}
