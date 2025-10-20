//
//  Insight.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import Foundation
import SwiftUI

struct Insight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}
