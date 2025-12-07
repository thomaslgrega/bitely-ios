//
//  IngredientRowView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/5/25.
//

import SwiftUI

struct IngredientRowView: View {
    @Binding var ingredient: Ingredient
    var onDelete: (Ingredient) -> Void

    var body: some View {
        HStack {
            if ingredient.isParsed {
                TextField("Qty", value: $ingredient.measurementQty, format: .number)
                    .keyboardType(.decimalPad)

                Picker("", selection: Binding(
                    get: { ingredient.measurementUnit ?? MeasurementUnit.none },
                    set: { ingredient.measurementUnit = $0 }
                )) {
                    ForEach(MeasurementUnitCategory.allCases, id: \.self) { category in
                        Section(category.rawValue) {
                            ForEach(category.units, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                    }
                }
                .pickerStyle(.menu)

                TextField("Ingredient Name", text: $ingredient.name, axis: .vertical)
            } else {
                Text(ingredient.measurementRaw)
                Text(ingredient.name)
            }

            Spacer()
            Button(role: .destructive) {
                onDelete(ingredient)
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    IngredientRowView(
        ingredient: .constant(Ingredient(id: "1", name: "Lemon Juice", measurementRaw: "1 cup", measurementQty: 1, measurementUnit: MeasurementUnit.cup, isParsed: true)),
        onDelete: { _ in }
    )
}
