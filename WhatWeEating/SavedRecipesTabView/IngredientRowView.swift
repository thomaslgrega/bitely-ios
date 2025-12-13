//
//  IngredientRowView.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 12/5/25.
//

import SwiftUI

struct IngredientRowView: View {
    @Binding var ingredient: Ingredient
    var onDelete: () -> Void

    var body: some View {
        HStack {
            if ingredient.isParsed {
                TextField("Qty", value: $ingredient.measurementQty, format: .number.precision(.fractionLength(0...2)))
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
                onDelete()
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    IngredientRowView(
        ingredient: .constant(Ingredient(name: "Lemon Juice", measurementRaw: "1 cup", measurementQty: 1, measurementUnit: MeasurementUnit.cup, isParsed: true)),
        onDelete: { }
    )
}
