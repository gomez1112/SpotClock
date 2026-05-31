import SwiftUI

extension View {
  func appCard(
    fill: Color = DesignSystem.cardBackground,
    cornerRadius: CGFloat = DesignSystem.cardCornerRadius
  ) -> some View {
    modifier(AppCardModifier(fill: fill, cornerRadius: cornerRadius))
  }

  func appContentWidth(_ maxWidth: CGFloat = DesignSystem.maxContentWidth) -> some View {
    frame(maxWidth: maxWidth)
      .frame(maxWidth: .infinity)
  }
}
