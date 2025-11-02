//
//  InsightsView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/19/25.
//

import SwiftUI
import Charts
import MapKit
import SwiftData

struct InsightsView: View {
    @Query private var sessions: [ParkingSession]
    @State private var selectedTimeframe: Timeframe = .month
    @State private var showBadgeAnimation = false
    @State private var pulseAnimation = false
    @State private var selectedAchievement: Achievement?
    @State private var showNewTimer = false
    
    @State private var cachedTopLocations: [LocationData] = []
    @State private var cachedWeeklyData: [WeeklyData] = []
    @State private var cachedTimeDistribution: [TimeDistributionData] = []
    @State private var lastComputedTimeframe: Timeframe?
    @State private var lastFilteredCount = 0
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    var body: some View {
        NavigationStack {
                ScrollView {
                    VStack(spacing: 28) {
                        // Elegant timeframe picker
                        timeframePicker
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .onChange(of: selectedTimeframe) { _, newValue in
                                recomputeCachedValues()
                            }
                        
                        if filteredSessions.isEmpty {
                            emptyStateView
                                .padding(.top, 60)
                                .id("empty-\(sessions.count)")
                        } else {
                            Group {
                                // Hero celebration section
                                heroSection
                                    .padding(.horizontal, 20)
                                
                                // Quick stats cards
                                quickStatsSection
                                    .padding(.horizontal, 20)
                                
                                // Smart insights with beautiful cards
                                insightsSection
                                    .padding(.horizontal, 20)
                                
                                // Stunning visual charts
                                analyticsSection
                                    .padding(.horizontal, 20)
                                
                                // Interactive heatmap
                                heatmapSection
                                    .padding(.horizontal, 20)
                                
                                // Achievement showcase
                                achievementsSection
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 40)
                            }
                            .id("content-\(filteredSessions.count)")
                        }
                            
                    }
                }
                .scrollIndicators(.hidden)
        
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showNewTimer) {
                NewTimerView()
            }
            .task(recomputeCachedValues)
            .onChange(of: filteredSessions.count) { oldValue, newValue in
                if oldValue != newValue {
                    recomputeCachedValues()
                    lastFilteredCount = newValue
                }
            }
        }
    }
    private func recomputeCachedValues() {
        guard lastComputedTimeframe != selectedTimeframe else { return }
        
        cachedTopLocations = computeTopLocations()
        cachedWeeklyData = computeWeeklyData()
        cachedTimeDistribution = computeTimeDistribution()
        lastComputedTimeframe = selectedTimeframe
    }
    private func computeTopLocations() -> [LocationData] {
        var locationDict: [String: [ParkingSession]] = [:]
        
        for session in filteredSessions where !session.location.isEmpty {
            locationDict[session.location, default: []].append(session)
        }
        
        let locations = locationDict.map { location, sessions in
            let avgLat = sessions.map { $0.latitude }.reduce(0, +) / Double(sessions.count)
            let avgLon = sessions.map { $0.longitude }.reduce(0, +) / Double(sessions.count)
            let avgDuration = sessions.map { $0.duration }.reduce(0, +) / Double(sessions.count)
            
            return LocationData(
                name: location,
                visits: sessions.count,
                coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                averageDuration: avgDuration
            )
        }
        
        return locations.sorted { $0.visits > $1.visits }
    }
    private func computeWeeklyData() -> [WeeklyData] {
        let calendar = Calendar.current
        let now = Date()
        var data: [WeeklyData] = []
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            let daySessions = filteredSessions.filter {
                calendar.isDate($0.startTime, inSameDayAs: date)
            }
            
            let totalHours = daySessions.reduce(0.0) { $0 + $1.duration / 3600 }
            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            data.append(WeeklyData(day: dayName, hours: totalHours, date: date))
        }
        
        return data
    }
    
    private func computeTimeDistribution() -> [TimeDistributionData] {
        var morning = 0
        var afternoon = 0
        var evening = 0
        var night = 0
        
        for session in filteredSessions {
            let hour = Calendar.current.component(.hour, from: session.startTime)
            
            switch hour {
                case 6..<12: morning += 1
                case 12..<18: afternoon += 1
                case 18..<24: evening += 1
                default: night += 1
            }
        }
        
        return [
            TimeDistributionData(period: "Morning", count: morning, color: .yellow),
            TimeDistributionData(period: "Afternoon", count: afternoon, color: .orange),
            TimeDistributionData(period: "Evening", count: evening, color: .purple),
            TimeDistributionData(period: "Night", count: night, color: .blue)
        ].filter { $0.count > 0 }
    }
    // MARK: - Timeframe Picker
    private var timeframePicker: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Insights Yet", systemImage: "chart.xyaxis.line")
        } description: {
            Text("Start parking to unlock beautiful\nanalytics and achievements")
        } actions: {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showNewTimer = true
            } label: {
                Text("Start Parking")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack {
            Color.indigo
            
            VStack(spacing: 24) {
                // Main celebration
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .symbolEffect(.bounce, value: ticketsAvoided)
                        
                        Text("\(ticketsAvoided)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    }
                    
                    Text("Tickets Avoided")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .textCase(.uppercase)
                        .tracking(2)
                }
                
                // Money saved highlight
                HStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("$\(moneySaved)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Money Saved")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .textCase(.uppercase)
                            .tracking(1.5)
                    }
                    
                    Divider()
                        .frame(height: 60)
                        .overlay(.white.opacity(0.3))
                    
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text("\(streakDays)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                                .symbolEffect(.pulse, value: streakDays)
                        }
                        Text("Day Streak")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .textCase(.uppercase)
                            .tracking(1.5)
                    }
                }
            }
            .padding(32)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "clock.fill",
                value: "\(Int(totalHoursParked))h",
                label: "Total Hours",
                gradient: [.blue, .cyan]
            )
            
            StatCard(
                icon: "chart.bar.fill",
                value: formatDuration(averageDuration),
                label: "Avg Duration",
                gradient: [.purple, .pink]
            )
            
            StatCard(
                icon: "mappin.circle.fill",
                value: "\(filteredSessions.count)",
                label: "Sessions",
                gradient: [.orange, .red]
            )
        }
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.indigo)
                
                Text("Smart Insights")
                    .font(.title2.bold())
            }
            .padding(.horizontal, 4)
            
            let insights = generateInsights()
            if insights.isEmpty {
                ContentUnavailableView {
                    Label("No Insights Yet", systemImage: "lightbulb.fill")
                        .symbolRenderingMode(.multicolor)
                } description: {
                    Text("Keep parking to unlock personalized insights")
                }
            } else {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
    
    // MARK: - Analytics Section
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Analytics")
                    .font(.title2.bold())
            }
            .padding(.horizontal, 4)
            
            // Duration trend chart
            if !weeklyData.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Weekly Parking Duration")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    Chart(weeklyData) { data in
                        BarMark(
                            x: .value("Day", data.day),
                            y: .value("Hours", data.hours)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(8)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let hours = value.as(Double.self) {
                                    Text("\(Int(hours))h")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 15, y: 8)
            }
            
            // Time distribution donut chart
            if !timeDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Time of Day Distribution")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    HStack(spacing: 30) {
                        // Donut chart
                        Chart(timeDistribution) { data in
                            SectorMark(
                                angle: .value("Count", data.count),
                                innerRadius: .ratio(0.618),
                                angularInset: 2
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [data.color, data.color.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(4)
                        }
                        .frame(width: 140, height: 140)
                        Spacer()
                        // Legend
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(timeDistribution) { data in
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(data.color)
                                        .frame(width: 12, height: 12)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(data.period)
                                            .font(.subheadline.weight(.semibold))
                                        Text("\(data.count) sessions")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 15, y: 8)
            }
            
            // Top locations
            if !topLocations.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Most Visited Locations")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(topLocations.prefix(5).enumerated(), id: \.element.id) { index, location in
                            LocationRow(location: location, rank: index + 1)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: .black.opacity(0.05), radius: 15, y: 8)
            }
        }
    }
    
    // MARK: - Heatmap Section
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Parking Hotspots")
                    .font(.title2.bold())
            }
            .padding(.horizontal, 4)
            
            if !topLocations.isEmpty {
                ParkingHeatmapView(locations: topLocations)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            }
        }
    }
    
    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Achievements")
                    .font(.title2.bold())
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                        .onTapGesture {
                            if achievement.isUnlocked {
                                selectedAchievement = achievement
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [ParkingSession] {
        let calendar = Calendar.current
        let now = Date()
        
        return sessions.filter { session in
            switch selectedTimeframe {
                case .week:
                    return calendar.isDate(session.startTime, equalTo: now, toGranularity: .weekOfYear)
                case .month:
                    return calendar.isDate(session.startTime, equalTo: now, toGranularity: .month)
                case .year:
                    return calendar.isDate(session.startTime, equalTo: now, toGranularity: .year)
                case .all:
                    return true
            }
        }
    }
    
    private var ticketsAvoided: Int {
        filteredSessions.count
    }
    
    private var moneySaved: Int {
        ticketsAvoided * 75
    }
    
    private var streakDays: Int {
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        // 1. Create a set of unique days the user parked. This is extremely fast.
        let uniqueParkingDays: Set<Date> = Set(
            sessions.map { calendar.startOfDay(for: $0.startTime) }
        )
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        let maxIterations = 1000
        var iterations = 0
        // 2. Loop backwards from today and check for consecutive days in the set.
        while uniqueParkingDays.contains(currentDate) && iterations < maxIterations {
            streak += 1
            // Move to the previous day
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
            iterations += 1
        }
        
        return streak
    }
    
    private var totalHoursParked: Double {
        filteredSessions.reduce(0) { $0 + $1.duration / 3600 }
    }
    
    private var averageDuration: TimeInterval {
        guard !filteredSessions.isEmpty else { return 0 }
        let total = filteredSessions.reduce(0.0) { $0 + $1.duration }
        return total / Double(filteredSessions.count)
    }
    
    private var weeklyData: [WeeklyData] {
        cachedWeeklyData
    }
    
    private var topLocations: [LocationData] {
        cachedTopLocations
    }
    
    private var timeDistribution: [TimeDistributionData] {
        cachedTimeDistribution
    }
    
    private var achievements: [Achievement] {
        var achievements: [Achievement] = []
        let sessionCount = sessions.count
        
        achievements.append(Achievement(
            icon: "star.fill",
            title: "Perfect Parker",
            description: "30 days ticket-free",
            isUnlocked: streakDays >= 30,
            date: Date(),
            color: .yellow
        ))
        
        achievements.append(Achievement(
            icon: "flag.fill",
            title: "First Timer",
            description: "Complete first session",
            isUnlocked: sessionCount >= 1,
            date: sessions.first?.startTime ?? Date(),
            color: .green
        ))
        
        let weekendSessions = sessions.filter {
            let weekday = Calendar.current.component(.weekday, from: $0.startTime)
            return weekday == 1 || weekday == 7
        }
        achievements.append(Achievement(
            icon: "sun.max.fill",
            title: "Weekend Warrior",
            description: "10 weekend sessions",
            isUnlocked: weekendSessions.count >= 10,
            date: Date(),
            color: .orange
        ))
        
        let morningSessions = sessions.filter {
            let hour = Calendar.current.component(.hour, from: $0.startTime)
            return hour >= 6 && hour < 9
        }
        achievements.append(Achievement(
            icon: "sunrise.fill",
            title: "Early Bird",
            description: "25 morning parks",
            isUnlocked: morningSessions.count >= 25,
            date: Date(),
            color: .cyan
        ))
        
        let nightSessions = sessions.filter {
            let hour = Calendar.current.component(.hour, from: $0.startTime)
            return hour >= 21 || hour < 6
        }
        achievements.append(Achievement(
            icon: "moon.stars.fill",
            title: "Night Owl",
            description: "15 night parks",
            isUnlocked: nightSessions.count >= 15,
            date: Date(),
            color: .indigo
        ))
        
        achievements.append(Achievement(
            icon: "crown",
            title: "Century Club",
            description: "100 sessions",
            isUnlocked: sessionCount >= 100,
            date: Date(),
            color: .purple
        ))
        
        achievements.append(Achievement(
            icon: "dollarsign.circle.fill",
            title: "Money Saver",
            description: "Save $1000",
            isUnlocked: sessions.count * 75 >= 1000,
            date: Date(),
            color: .green
        ))
        
        let longSessions = sessions.filter { $0.duration >= 14400 }
        achievements.append(Achievement(
            icon: "timer",
            title: "Marathon Parker",
            description: "Park for 4+ hours",
            isUnlocked: !longSessions.isEmpty,
            date: longSessions.first?.startTime ?? Date(),
            color: .red
        ))
        
        return achievements
    }
    
    private func generateInsights() -> [Insight] {
        var insights: [Insight] = []
        
        guard filteredSessions.count >= 3 else {
            return insights
        }
        
        let dayFrequency = Dictionary(grouping: filteredSessions) {
            Calendar.current.component(.weekday, from: $0.startTime)
        }
        if let mostFrequentDay = dayFrequency.max(by: { $0.value.count < $1.value.count }) {
            let dayName = Calendar.current.weekdaySymbols[mostFrequentDay.key - 1]
            insights.append(Insight(
                icon: "calendar",
                title: "Peak Day: \(dayName)s",
                description: "You park most on \(dayName)s (\(mostFrequentDay.value.count) times)",
                color: .blue
            ))
        }
        
        let avgHour = filteredSessions.map {
            Calendar.current.component(.hour, from: $0.startTime)
        }.reduce(0, +) / filteredSessions.count
        
        let timeOfDay: String
        if avgHour < 12 {
            timeOfDay = "morning (\(avgHour):00 AM)"
        } else if avgHour < 17 {
            timeOfDay = "afternoon (\(avgHour - 12):00 PM)"
        } else {
            timeOfDay = "evening (\(avgHour - 12):00 PM)"
        }
        
        insights.append(Insight(
            icon: "clock.fill",
            title: "Typical Time",
            description: "You usually park in the \(timeOfDay)",
            color: .orange
        ))
        
        if let topLocation = topLocations.first {
            insights.append(Insight(
                icon: "mappin.circle.fill",
                title: "Favorite Spot",
                description: "\(topLocation.name) • \(topLocation.visits) visits",
                color: .green
            ))
        }
        
        let avgDurationHours = averageDuration / 3600
        insights.append(Insight(
            icon: "hourglass",
            title: "Average Stay",
            description: String(format: "You typically park for %.1f hours", avgDurationHours),
            color: .purple
        ))
        
        if selectedTimeframe == .month {
            let monthlySavings = ticketsAvoided * 75
            if monthlySavings >= 200 {
                insights.append(Insight(
                    icon: "banknote.fill",
                    title: "Big Saver!",
                    description: "You've saved $\(monthlySavings) this month",
                    color: .green
                ))
            }
        }
        
        if streakDays >= 7 {
            insights.append(Insight(
                icon: "flame.fill",
                title: "On Fire! 🔥",
                description: "\(streakDays)-day streak! Keep it going!",
                color: .orange
            ))
        }
        
        let extendedCount = filteredSessions.filter { $0.wasExtended }.count
        if extendedCount > filteredSessions.count / 2 {
            insights.append(Insight(
                icon: "arrow.clockwise.circle.fill",
                title: "Extension Expert",
                description: "You extend \(Int(Double(extendedCount) / Double(filteredSessions.count) * 100))% of sessions",
                color: .cyan
            ))
        }
        
        return insights
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview(traits: .previewData) {
    InsightsView()
}
