import SwiftUI
import SwiftData

@main
struct BitelyApp: App {
    private let authStore: AuthStore
    private let authService: AuthService
    private let recipeService: RecipeService
    private let recipeStore: RecipeStore
    private let cookbook: Cookbook

    init() {
        let store = AuthStore()
        let client = APIClient(authStore: store)
        let recipes = RecipeService(api: client)

        self.authStore = store
        self.authService = AuthService(api: client, authStore: store)
        self.recipeService = recipes
        // Held by the app, not by Discover: a store rebuilt on every appearance would
        // refetch the Feed each time the user came back to the tab.
        self.recipeStore = RecipeStore(service: recipes)
        self.cookbook = Cookbook(service: recipes, authStore: store)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environment(authStore)
                .environment(authService)
                .environment(recipeService)
                .environment(recipeStore)
                .environment(cookbook)
                .task {
                    await authService.bootstrap()
                }
        }
        .modelContainer(for: [Recipe.self, ShoppingList.self, MealPlanDay.self])
    }
}
