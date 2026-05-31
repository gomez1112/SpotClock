import SwiftUI

struct AppCardModifier: ViewModifier {
  var fill: Color = DesignSystem.cardBackground
  var cornerRadius: CGFloat = DesignSystem.cardCornerRadius

  func body(content: Content) -> some View {
    content
      .background(fill, in: .rect(cornerRadius: cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .strokeBorder(DesignSystem.cardStroke(), lineWidth: 1)
      )
      .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
  }
}
