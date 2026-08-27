import SwiftData
import SwiftUI

struct CalendarTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var showSettingsSheet = false
    @Query var mealPlanDays: [MealPlanDay]

    var selectedDateMealPlan: MealPlanDay? {
        mealPlanDays.first(where: { $0.dayKey == selectedDate.dayKey })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    DatePickerView(selectedDate: $selectedDate)

                    if let mealPlanDay = selectedDateMealPlan {
                        MealPlanDayView(mealPlanDay: mealPlanDay)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xxxl)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.surface)
            .onAppear {
                loadMealPlanDay()
            }
            .onChange(of: selectedDate) { _, _ in
                loadMealPlanDay()
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
            .toolbar {
                Button {
                    showSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .tint(Color.contentPrimary)
                .accessibilityLabel("Settings")
            }
        }
    }

    func loadMealPlanDay() {
        if selectedDateMealPlan == nil {
            let newMealPlanDay = MealPlanDay(dayKey: selectedDate.dayKey)
            modelContext.insert(newMealPlanDay)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MealPlanDay.self, configurations: config)
    CalendarTabView()
        .modelContainer(container)
}
