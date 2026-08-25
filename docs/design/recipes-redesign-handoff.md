# Recipes redesign — handoff

Written 2026-08-25, at the end of the exploration session. This is the state a
planning or grilling session should start from.

## The decision

**Direction: Editorial Feed, set in Fraunces.** Chosen from five explorations
after comparing them side by side in the simulator.

Editorial Feed is `Bitely/Views/DesignExplorations/EditorialFeedRecipesView.swift`.
Its shape, top to bottom:

- Greeting bar — avatar, "Welcome, <name>", search button, settings button.
- One dark promo card carrying the pantry search ("Cook what you have").
- A horizontal category chip rail that filters the grid **in place**; the chips
  do not navigate. A long-press context menu opens the full category list.
- A two-column Recipe grid — square image tile, save heart floating on the tile,
  serif name, cook time and calories.

## Palette and type

From the inspiration board, defined in `RedesignMockData.swift` as `Redesign`:

| Token | Hex | Role |
| --- | --- | --- |
| `cream` | `#FFFBF7` | Page background |
| `red` | `#932D2C` | Accent, saved state, section links |
| `ink` | `#24211D` | Type, promo card, primary buttons |
| `inkSoft` | `#6B655C` | Secondary type |
| `hairline` | `#E8E0D6` | Card borders |

Plus one soft tint per `FoodCategory` (`Redesign.tint(for:)`), which the mock
thumbnails use as their background — the inspiration shoots products on flat
color blocks, and that is what the tints stand in for.

Headings are Fraunces; body copy stays the system sans. Fraunces Regular and
SemiBold are bundled in `Bitely/Resources/Fonts/` and registered in
`Bitely/Info.plist` under `UIAppFonts`, along with four alternates kept for
comparison (Playfair Display, DM Serif Display, Instrument Serif, Bricolage
Grotesque). All ship under the SIL OFL; `Resources/Fonts/OFL.txt` covers them.

`Redesign.serif(_:_:)` resolves through `RedesignType.shared.typeface`, which
defaults to Fraunces. Committing to one face means that indirection and the
other seven font files can go.

## What exists, and what it is not

Everything lives in `Bitely/Views/DesignExplorations/` and **nothing is wired
into the shipping app**. `ContentView` still shows the current `RecipesTabView`.

- `EditorialFeedRecipesView.swift` — the chosen direction.
- `CrimsonHeaderRecipesView`, `MidnightKitchenRecipesView`,
  `MagazineIndexRecipesView`, `PantryFirstRecipesView` — the four not chosen.
- `RecipesRedesignGalleryView.swift` — the comparison harness: a list, a
  side-by-side strip, and the typeface bar.
- `RedesignMockData.swift` — `MockRecipe`, sample data, palette, thumbnail,
  save button. `MockRecipeStore` is an `@Observable` stand-in for bookmarks and
  the pantry.
- `RedesignDestinations.swift` — the shared pushed screens (category list,
  pantry search, recipe detail, settings) and a `FlowRow` layout.

These are mock views: no SwiftData, no `RecipeService`, no network, no tests.
They demonstrate layout, not behaviour.

## What the real tab does today

`RecipesTabView` is a `NavigationStack` over a `ScrollView` with a pantry-search
`NavigationLink` followed by one row per `FoodCategory`, plus a settings sheet
in the toolbar. Tapping a category pushes `RecipeListView`, which fetches
`recipeService.getRecipesByCategory` into a two-column grid of
`RecipeListCardView`. That card is where bookmarking lives: it reads `@Query`
over local `Recipe`s to decide bookmarked state, and on tap fetches the full
Recipe and inserts it into the `modelContext`, or deletes it behind a
confirmation alert.

## Open questions worth grilling

1. **The chip rail replaces category navigation.** Filtering in place is not
   what the tab does today — categories are a push. Does the pushed
   `RecipeListView` survive at all, or does the grid become the only surface?
   The mock hedges by keeping the push on a long-press, which no one will find.
2. **Where does the grid's content come from?** "Popular now" is invented. The
   API is queried per category; an unfiltered feed needs an endpoint or a
   client-side merge that does not exist yet.
3. **The greeting needs a name.** `User` and `AuthStore` exist, but the tab is
   usable signed out. What does the bar say then?
4. **The search button in the greeting bar** currently goes to the pantry
   search, duplicating the promo card. Either it becomes a real name search
   (new API surface) or it goes.
5. **Bookmark affordance changes shape** — a heart on the image rather than a
   bookmark glyph in a capsule. The delete confirmation alert in
   `RecipeListCardView` has to land somewhere in the new card.
6. **Category tints assume ten known cases**, but `FoodCategory(apiValue:)`
   folds anything unrecognized into `.other`. Every unknown category lands on
   one tint.
7. **Scope.** This is one tab of five. Calendar, Shopping List, Saved and Shared
   still carry the coral/slate palette from `Extensions/Color.swift`. Is this a
   tab-by-tab migration or one cutover, and does `Color.primaryMain` get
   redefined or replaced?
8. **Dark mode.** `BitelyApp` pins `.preferredColorScheme(.light)`. The cream
   palette is light-only as drawn; Midnight Kitchen showed the dark half of the
   palette works, but nothing maps the tokens across schemes.

## Verified

Build and the full test suite pass on iPhone 17 (`xcodebuild test`, all
existing tests green). Every exploration was screenshotted running in the
simulator. All work is uncommitted.
