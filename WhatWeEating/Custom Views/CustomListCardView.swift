//
//  CustomListCardView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/17/25.
//

import SwiftUI

struct CustomListCardView: View {
    let mainText: String
    let trailingIcon: String
    let onTapAction: () -> Void

    var body: some View {
        HStack {
            Text(mainText)
                .padding()
            Spacer()
            Image(systemName: trailingIcon)
                .foregroundStyle(Color.primaryMain)
                .padding()
        }
        .frame(minHeight: 50)
        .background(Color.secondary100)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary200, lineWidth: 1)
        )
        .onTapGesture {
            onTapAction()
        }
    }
}

#Preview {
    CustomListCardView(mainText: "French Toast", trailingIcon: "trash", onTapAction: {})
}
