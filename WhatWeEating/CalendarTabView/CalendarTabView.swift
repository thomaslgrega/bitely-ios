//
//  CalendarTabView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 4/29/25.
//

import SwiftUI

struct CalendarTabView: View {
    var body: some View {
        CalendarView()
        Divider()
        RecipeListView()
    }
}

#Preview {
    CalendarTabView()
}
