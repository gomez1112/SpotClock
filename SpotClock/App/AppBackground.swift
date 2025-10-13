//
//  AppBackground.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//


//  AppBackground.swift
//  SpotClock

import SwiftUI

/// A gentle, ADA-friendly background with depth.
/// Uses system background + a soft radial highlight + subtle grain via material.
struct AppBackground: View {
    var body: some View {
        Color(.systemBackground)
            .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
