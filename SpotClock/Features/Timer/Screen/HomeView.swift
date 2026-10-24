import SwiftUI

@available(iOS 27.1, *)
struct HomeView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showNewTimer = false
    @State private var showSubscription = false
    @State private var selectedDuration: TimeInterval = 3600

    var body: some View {
        NavigationStack {
            parkingContent
            .background { AppBackground() }
            .navigationTitle("SpotClock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !subscriptionService.hasProAccess {
                    ToolbarItem(placement: .primaryAction) {
                        Button("SpotClock Pro", systemImage: "crown") { showSubscription = true }
                    }
                }
            }
            .sheet(isPresented: $showNewTimer) { NewTimerView(initialDuration: selectedDuration) }
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
        }
    }

    @ViewBuilder
    private var parkingContent: some View {
        if timerService.isRunning, let session = timerService.activeSession {
            ActiveTimerView(session: session)
        } else {
            idleParking
        }
    }

    private var idleParking: some View {
        ArrangementView {
            parkingSetup.splitArrangementLayoutSize(minWidth: 300)
        } secondary: {
            ParkingReadyMapView().splitArrangementLayoutSize(minWidth: 300)
        }
        .arrangementViewStyle(.split.axes(arrangementAxes))
    }

    private var arrangementAxes: Axis.Set {
        if horizontalSizeClass == .regular { return [.horizontal, .vertical] }
        return .horizontal
    }

    private var parkingSetup: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PARKING, AT YOUR PACE")
                        .font(.caption2.weight(.semibold)).tracking(2)
                        .foregroundStyle(DesignSystem.warmAccent)
                    Text("Time, on your side.")
                        .font(.system(.largeTitle, design: .serif)).tracking(-0.8)
                    Text("Choose your stay. Leave the clock to us.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ParkingDialView(progress: 1, time: durationText, caption: "hours · minutes", maximumDiameter: 240)
                durationPicker
                Label("Return at \(Date.now.addingTimeInterval(selectedDuration).formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                    .font(.subheadline).foregroundStyle(.secondary)
                Divider().overlay(DesignSystem.warmAccent.opacity(0.2))
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "mappin.and.ellipse").foregroundStyle(DesignSystem.warmAccent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("A place to come back to.").font(.subheadline.weight(.medium))
                        Text("Your location is saved when you start.").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(24)
            .appContentWidth(540)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            Button {
                if subscriptionService.canStartSession { showNewTimer = true }
                else { showSubscription = true }
            } label: {
                HStack {
                    Image(systemName: "parkingsign")
                    Text("Start parking").font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white).padding(20)
                .background(DesignSystem.ink, in: .rect(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24).padding(.vertical, 12)
            .appContentWidth(540)
            .background(DesignSystem.appBackground)
            .accessibilityIdentifier("parking.start")
            .accessibilityHint("Review your parking spot and start the timer.")
        }
    }

    @ViewBuilder private var durationPicker: some View {
        if dynamicTypeSize.isAccessibilitySize { presets.pickerStyle(.menu) }
        else { presets.pickerStyle(.segmented) }
    }

    private var presets: some View {
        Picker("Parking duration", selection: $selectedDuration) {
            Text("15 min").tag(TimeInterval(900))
            Text("30 min").tag(TimeInterval(1800))
            Text("1 hour").tag(TimeInterval(3600))
            Text("2 hours").tag(TimeInterval(7200))
        }
    }

    private var durationText: String {
        let hours = Int(selectedDuration) / 3600
        let minutes = Int(selectedDuration) % 3600 / 60
        return "\(hours):\(minutes.formatted(.number.precision(.integerLength(2))))"
    }
}
