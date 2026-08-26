import SwiftUI

/// A `sectionTitle` heading with an optional trailing action in `accent`.
struct SectionHeader<Action: View>: View {
    let title: String
    @ViewBuilder let action: () -> Action

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .textStyle(.sectionTitle)
                .foregroundStyle(Color.contentPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            action()
                .buttonStyle(.textAction)
        }
    }
}

extension SectionHeader {
    init(_ title: String, @ViewBuilder action: @escaping () -> Action) {
        self.init(title: title, action: action)
    }
}

extension SectionHeader where Action == EmptyView {
    init(_ title: String) {
        self.init(title: title) { EmptyView() }
    }
}

#Preview {
    VStack(spacing: Spacing.xxl) {
        SectionHeader("Today's Picks")
        SectionHeader("Browse by category") {
            Button("Clear") {}
        }
    }
    .padding()
    .background(Color.surface)
}
