//
//  HistoryView.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//

import SwiftUI
import SwiftData
import MapKit
import OSLog

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParkingSession.startTime, order: .reverse) private var sessions: [ParkingSession]
    @State private var selectedSession: ParkingSession?
    @State private var showMap = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                if sessions.isEmpty {
                    emptyState
                } else {
                    sessionsList
                }
            }
            .navigationTitle("History")
            .sheet(item: $selectedSession) { session in
                MapView(session: session)
            }
        }
    }
    
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.brandIndigo.opacity(0.12))
                        .frame(width: 160, height: 160)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundStyle(DesignSystem.brandIndigo)
                }

                VStack(spacing: 12) {
                    Text("No Parking History")
                        .font(.title.bold())

                    Text("Your parking sessions will appear here.\nStart your first timer to get going!")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .padding()
            .appContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var sessionsList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Places you’ve been.")
                        .font(.system(.title, design: .serif))
                        .tracking(-1)
                    Text("\(sessions.count) stays, thoughtfully remembered.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            ForEach(groupedSessions, id: \.key) { group in
                Section(formatSectionHeader(group.key)) {
                    ForEach(group.value) { session in
                        ImprovedSessionRow(session: session) {
                            selectedSession = session
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var groupedSessions: [(key: Date, value: [ParkingSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatSectionHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return date.formatted(.dateTime.weekday(.wide))
        } else {
            return date.formatted(.dateTime.month(.wide).day())
        }
    }
}

struct ImprovedSessionRow: View {
    let session: ParkingSession
    let onMapTap: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SpotClock", category: "History")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: statusIcon)
                        .font(.title3)
                        .foregroundStyle(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.location.isEmpty ? "Unknown Location" : session.location)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(session.startTime.formatted(.dateTime.hour().minute()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if session.wasExtended {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
            }
            
            // Stats row
            HStack(spacing: 24) {
                statItem(icon: "timer", text: formatDuration(session.duration))
                statItem(icon: "calendar", text: formatDate(session.startTime))
                
                Spacer()
                
                if session.latitude != 0 && session.longitude != 0 {
                    Button {
                        onMapTap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "map.fill")
                            Text("Map")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(DesignSystem.brandBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DesignSystem.softAccent, in: Capsule())
                    }
                }
            }
            
            // Notes if available
            if !session.notes.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation {
                    modelContext.delete(session)
                    do {
                        try modelContext.save()
                    } catch {
                        logger.error("Failed to delete session: \(error.localizedDescription, privacy: .public)")
                        deleteErrorMessage = error.localizedDescription
                        showDeleteError = true
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Couldn’t Delete Session", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
    }
    
    private func statItem(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
    
    private var statusIcon: String {
        session.isExpired ? "checkmark.circle.fill" : "clock.fill"
    }
    
    private var statusColor: Color {
        session.isExpired ? DesignSystem.brandTeal : DesignSystem.brandBlue
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
    
    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}
