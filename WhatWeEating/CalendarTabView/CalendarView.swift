//
//  CalendarView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/29/25.
//

import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date

    var body: some View {
        DatePicker(
            "Select a date",
            selection: $selectedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .frame(width: 320, height: 400)
    }
}

#Preview {
    CalendarView(selectedDate: .constant(Date()))
}
