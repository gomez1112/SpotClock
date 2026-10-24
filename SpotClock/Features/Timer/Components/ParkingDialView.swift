import SwiftUI

/// A quiet, high-contrast instrument with a flexible readout for larger text.
struct ParkingDialView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var progress: Double
    var time: String
    var caption: String
    var maximumDiameter: CGFloat = 280

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                readout.padding(.vertical, 24)
            } else {
                ZStack {
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let radius = min(size.width, size.height) / 2 - 5
                        for tick in 0..<60 {
                            let angle = Double(tick) * .pi / 30
                            let major = tick.isMultiple(of: 5)
                            let length = major ? 13.0 : 5.0
                            var mark = Path()
                            mark.move(to: CGPoint(x: center.x + sin(angle) * (radius - length), y: center.y - cos(angle) * (radius - length)))
                            mark.addLine(to: CGPoint(x: center.x + sin(angle) * radius, y: center.y - cos(angle) * radius))
                            context.stroke(mark, with: .color(.primary.opacity(major ? 0.55 : 0.18)), lineWidth: major ? 1.5 : 1)
                        }
                    }
                    Circle().inset(by: 24).stroke(.primary.opacity(0.06), lineWidth: 3)
                    Circle().inset(by: 24)
                        .trim(from: 0, to: min(1, max(0, progress)))
                        .stroke(DesignSystem.warmAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    readout.padding(35)
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: maximumDiameter)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityValue(time)
    }

    private var readout: some View {
        VStack(spacing: 8) {
            Image(systemName: "parkingsign")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DesignSystem.warmAccent)
                .accessibilityHidden(true)
            Text(time)
                .font(.system(.largeTitle, design: .rounded).weight(.light).scaled(by: 1.85))
                .tracking(-2)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .contentTransition(.numericText())
            Text(caption).font(.caption).foregroundStyle(.secondary)
        }
    }
}
