import SwiftUI

struct CustomSegmentedControl<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let options: [(value: SelectionValue, label: String)]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element.value) { _, option in
                    Button {
                        withAnimation(.snappy) {
                            selection = option.value
                        }
                    } label: {
                        Text(option.label)
                            .textStyle(.label)
                            .foregroundStyle(selection == option.value ? Color.accent : Color.contentSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.m)
                    }
                }
            }

            GeometryReader { geo in
                let segmentWidth = geo.size.width / CGFloat(options.count)
                let selectedIndex = options.firstIndex(where: { $0.value == selection }) ?? 0

                Rectangle()
                    .fill(Color.accent)
                    .frame(width: segmentWidth, height: 3)
                    .offset(x: segmentWidth * CGFloat(selectedIndex))
            }
            .frame(height: 3)
        }
        .background(Color.surfaceRaised)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: Radius.control,
                topTrailingRadius: Radius.control,
                style: .continuous
            )
        )
    }
}

private struct CustomSegmentedControlPreview: View {
    @State private var selection = 0

    var body: some View {
        CustomSegmentedControl(
            selection: $selection,
            options: [(0, "My recipes"), (1, "Saved")]
        )
        .padding()
        .background(Color.surface)
    }
}

#Preview { CustomSegmentedControlPreview() }
