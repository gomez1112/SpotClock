import SwiftUI

struct AppSectionHeader: View {
  var title: String
  var systemImage: String
  var tint: Color = DesignSystem.brandBlue

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .font(.headline)
        .foregroundStyle(tint)
        .frame(width: 32, height: 32)
        .background(tint.opacity(0.12), in: .circle)

      Text(title)
        .font(.title3.bold())
        .foregroundStyle(.primary)

      Spacer()
    }
    .accessibilityElement(children: .combine)
  }
}
