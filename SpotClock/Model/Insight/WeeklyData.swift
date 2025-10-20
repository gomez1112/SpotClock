//
//  WeeklyData.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import Foundation

struct WeeklyData: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
    let date: Date
}
