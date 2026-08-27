import Testing
@testable import Bitely

@Suite("Main tabs")
struct MainTabTests {

    @Test("four tabs, in the order the flow reads")
    func order() {
        #expect(MainTab.allCases == [.discover, .cookbook, .plan, .shop])
    }

    @Test(
        "each tab is labelled and lettered",
        arguments: [
            (MainTab.discover, "Discover", "fork.knife"),
            (MainTab.cookbook, "Cookbook", "book.closed"),
            (MainTab.plan, "Plan", "calendar"),
            (MainTab.shop, "Shop", "basket"),
        ]
    )
    func labels(tab: MainTab, title: String, systemImage: String) {
        #expect(tab.title == title)
        #expect(tab.systemImage == systemImage)
    }

    @Test("the app opens on Discover")
    func opensOnDiscover() {
        #expect(MainTab.initial == .discover)
    }
}
