import SwiftUI

struct MetaLabel: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: systemImage)
            Text(text)
        }
        .textStyle(.meta)
        .foregroundStyle(Color.contentSecondary)
        .accessibilityElement(children: .combine)
    }
}

extension MetaLabel {
    /// The two facts a Recipe may be missing. Both return nil rather than a placeholder,
    /// so a tile with no numbers shows no meta row instead of a row of dashes.
    static func cookTime(minutes: Int?) -> MetaLabel? {
        minutes.map { MetaLabel(systemImage: "clock", text: "\($0) min") }
    }

    static func calories(_ calories: Int?) -> MetaLabel? {
        calories.map { MetaLabel(systemImage: "flame", text: "\($0) cal") }
    }
}

#Preview {
    HStack(spacing: Spacing.m) {
        MetaLabel.cookTime(minutes: 35)
        MetaLabel.calories(640)
    }
    .padding()
    .background(Color.surface)
}
