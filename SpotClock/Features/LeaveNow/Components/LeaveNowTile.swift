//
//  LeaveNowTile.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import SwiftUI

struct LeaveNowTile: View {
    let leaveBy: Date?
    let isGoNow: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "figure.walk.motion")
                .imageScale(.large)
                .symbolRenderingMode(.hierarchical)
            VStack(alignment: .leading) {
                Text(isGoNow ? "Go Now" : "Leave By")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(isGoNow ? "Start Heading Back" : (leaveBy?.formatted(date: .omitted, time: .shortened) ?? "-"))
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: .capsule)
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
    }
}

#Preview {
    LeaveNowTile(leaveBy: Date(), isGoNow: true)
}
#Preview {
    LeaveNowTile(leaveBy: Date(), isGoNow: false)
}
