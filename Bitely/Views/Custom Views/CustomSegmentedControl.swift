//
//  CustomSegmentedControl.swift
//  Bitely
//
//  Created by Thomas Grega on 12/24/25.
//

import SwiftUI

struct CustomSegmentedControl<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let options: [(value: SelectionValue, label: String)]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element.value) { index, option in
                    Button {
                        withAnimation(.snappy) {
                            selection = option.value
                        }
                    } label: {
                        Text(option.label)
                            .font(.headline)
                            .foregroundStyle(selection == option.value ? Color.primaryMain : Color.secondaryMain)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }

            GeometryReader { geo in
                let segmentWidth = geo.size.width / CGFloat(options.count)
                let selectedIndex = options.firstIndex(where: { $0.value == selection }) ?? 0

                Rectangle()
                    .fill(Color.primaryMain)
                    .frame(width: segmentWidth, height: 3)
                    .offset(x: segmentWidth * CGFloat(selectedIndex))
            }
            .frame(height: 3)
        }
        .background(Color.secondary100)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
    }
}
