import SwiftUI

/// The 46×46 size is fixed: these sit in a row with the avatar, which does not grow with
/// Dynamic Type either.
struct CircleIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            face
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var face: some View {
        Image(systemName: systemImage)
            .font(.system(size: SymbolSize.control, weight: .medium))
            .foregroundStyle(Color.contentPrimary)
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .fill(Color.surfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .strokeBorder(Color.border, lineWidth: 1)
            )
    }
}

#Preview {
    HStack(spacing: Spacing.m) {
        CircleIconButton(systemImage: "magnifyingglass", accessibilityLabel: "Pantry Search") {}
        CircleIconButton(systemImage: "gearshape", accessibilityLabel: "Settings") {}
    }
    .padding()
    .background(Color.surface)
}
