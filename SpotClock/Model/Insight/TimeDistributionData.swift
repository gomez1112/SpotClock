//
//  TimeDistributionData.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import SwiftUI

struct TimeDistributionData: Identifiable {
    let id = UUID()
    let period: String
    let count: Int
    let color: Color
}
