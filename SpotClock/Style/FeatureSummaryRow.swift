import SwiftUI

struct FeatureSummaryRow: View {
    var title: LocalizedStringKey
    var detail: LocalizedStringKey
    var symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(DesignSystem.brandBlue)
                .frame(width: 44, height: 44)
                .background(DesignSystem.softAccent, in: .rect(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
