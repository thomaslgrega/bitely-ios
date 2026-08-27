import SwiftUI

struct DatePickerView: View {
    @Binding var selectedDate: Date

    var body: some View {
        DatePicker(
            "Select a date",
            selection: $selectedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .tint(Color.accent)
        .frame(maxWidth: .infinity)
        .frame(height: 400)
    }
}

#Preview {
    DatePickerView(selectedDate: .constant(Date()))
        .padding()
        .background(Color.surface)
}
