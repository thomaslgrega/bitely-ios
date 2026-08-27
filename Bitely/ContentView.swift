import SwiftUI

/// The four tabs — docs/design/app-flow.md. Settings is not among them: it hangs off
/// Discover's avatar, so there is one way to an account rather than one per toolbar.
enum MainTab: CaseIterable, Identifiable {
    case discover
    case cookbook
    case plan
    case shop

    static let initial = MainTab.discover

    var id: Self { self }

    var title: String {
        switch self {
        case .discover: "Discover"
        case .cookbook: "Cookbook"
        case .plan: "Plan"
        case .shop: "Shop"
        }
    }

    var systemImage: String {
        switch self {
        case .discover: "fork.knife"
        case .cookbook: "book.closed"
        case .plan: "calendar"
        case .shop: "basket"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: MainTab = .initial

    var body: some View {
        TabView(selection: $selectedTab) {
            // The bar is built from `allCases`, so the order the tests pin is the order
            // that ships rather than a second list kept in step by hand.
            ForEach(MainTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    screen(for: tab)
                }
            }
        }
        .tint(Color.accent)
    }

    @ViewBuilder
    private func screen(for tab: MainTab) -> some View {
        switch tab {
        case .discover: DiscoverView()
        case .cookbook: CookbookView()
        case .plan: CalendarTabView()
        case .shop: ShoppingListTabView()
        }
    }
}

#Preview {
    ContentView()
}
