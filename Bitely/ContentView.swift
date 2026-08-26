import SwiftUI

enum mainTabs {
    case calendar
    case shoppingList
    case searchRecipes
    case cookbook
}

struct ContentView: View {
    @State private var selectedTab: mainTabs = .searchRecipes

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Discover", systemImage: "fork.knife", value: .searchRecipes) {
                DiscoverView()
            }

            Tab("Calendar", systemImage: "calendar", value: .calendar) {
                CalendarTabView()
            }

            Tab("Shopping List", systemImage: "basket", value: .shoppingList) {
                ShoppingListTabView()
            }

            Tab("Cookbook", systemImage: "book.closed", value: .cookbook) {
                CookbookView()
            }
        }
        .tint(Color.primaryMain)
    }
}

#Preview {
    ContentView()
}
