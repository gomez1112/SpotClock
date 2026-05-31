//
//  AppBackground.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//


//  AppBackground.swift
//  SpotClock

import SwiftUI

struct AppBackground: View {
    var body: some View {
        DesignSystem.appBackground
            .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
