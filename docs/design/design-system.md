# Bitely design system

The visual system for the whole app, derived from the Editorial Feed direction in
[recipes-redesign-handoff.md](./recipes-redesign-handoff.md). Every screen is
built from the tokens and components here; a screen that needs something not on
this page needs this page changed first.

Why the token layer is shaped this way is [ADR-0001](../adr/0001-editorial-visual-system.md).

## Color

Two layers. The **brand palette** names the values and is referenced only by the
asset catalog. The **role tokens** are what views use. Dark values are filled in
now and unused: the app ships light-only.

### Brand palette

| Name | Light |
| --- | --- |
| `cream` | `#FFFBF7` |
| `ink` | `#24211D` |
| `inkSoft` | `#6B655C` |
| `red` | `#932D2C` |
| `hairline` | `#E8E0D6` |

### Role tokens

| Token | Light value | Used by |
| --- | --- | --- |
| `surface` | `cream` | Page background |
| `surfaceRaised` | white | Cards, chips, circle buttons |
| `surfaceInverse` | `ink` | Promo card, primary buttons |
| `contentPrimary` | `ink` | Headings, recipe names |
| `contentSecondary` | `inkSoft` | Meta labels, subcopy |
| `contentOnInverse` | `cream` | Type on `surfaceInverse` |
| `accent` | `red` | Selected chip, saved heart, links |
| `destructive` | `#C0392B` | Delete and unsave confirmations |
| `border` | `hairline` | Card, chip and control strokes |

`destructive` is deliberately hotter and less brown than `accent`: a saved heart
and a delete button must not read as the same color at a glance.

### Category tints

One tint per `FoodCategory`, the ground a recipe photo falls back to.

| Category | Tint | Category | Tint |
| --- | --- | --- | --- |
| Beef | `#E9C8C0` | Pork | `#E7CBC7` |
| Breakfast | `#F1DFC8` | Seafood | `#C9DBE2` |
| Chicken | `#F0DCC0` | Side | `#D6DFC8` |
| Dessert | `#EBD3DA` | Vegetarian | `#CDDCC6` |
| Pasta | `#F2E1BC` | Other | `#DDD8CE` |

`FoodCategory(apiValue:)` folds every unrecognized category into `.other`, so
Other's tint covers all of them. That is intended: Other is a real bucket and
should look like one. Tinting by the raw category string would make two recipes
look like they belong to categories that cannot be filtered to.

## Type

Fraunces for display cuts, the system sans for everything read in quantity.
Every size goes through `relativeTo:` so text scales with Dynamic Type.

| Token | Face | Size | Scales relative to |
| --- | --- | --- | --- |
| `display` | Fraunces SemiBold | 30 | `.title` |
| `sectionTitle` | Fraunces SemiBold | 24 | `.title2` |
| `greeting` | Fraunces SemiBold | 19 | `.title3` |
| `cardTitle` | Fraunces SemiBold | 16 | `.headline` |
| `body` | System | 15 | `.body` |
| `meta` | System | 13 | `.footnote` |
| `label` | System SemiBold | 14 | `.subheadline` |

Symbols are not on this scale: they sit inside fixed-size controls, so their point
sizes live in `SymbolSize` and hold still while the text around them grows.

**The type scale is mandatory.** A font size chosen at a call site is the way a
design system dies, and it is what the mock already does in a dozen places.

Fraunces is bundled in `Bitely/Resources/Fonts/` under the SIL OFL and registered
in `Info.plist` under `UIAppFonts`.

## Spacing and radius

Convention, not enforced. Reach for a scale value first; a layout that genuinely
needs `6` can have it.

**Spacing**: 4, 8, 12, 16, 20, 24, 32.

**Radius**: `control` 16, `card` 18, `promo` 26, and a capsule for chips and pill
buttons.

## Components

### RecipeThumbnail

The recipe photo when there is one, the category tint under the category icon
when there is not. Both cases carry the same radius and the same inset `border`
stroke, and photos take a slight warm overlay, so a grid mixing the two reads as
one set rather than as half-loaded.

### RecipeTile

`RecipeThumbnail` at 1:1 with a `SaveButton` floating top-trailing, the recipe
name in `cardTitle`, and a row of `MetaLabel`s for cook time and calories.
Intrinsically sized — no reserved line count — because the name grows with
Dynamic Type.

A grid whose whole tile is a button or a link — Discover, the Cookbook — passes
no `saveButton` and lays the heart over the tile itself, in the same
top-trailing position: a button nested in another button does not reliably take
its own taps.

### SaveButton

A heart on the thumbnail. Filled `accent` when saved. Unsaving always confirms:
it deletes a local Recipe whose ingredients and instructions may have been
edited, and a heart is a light enough control that a silent second tap would be
destructive.

### CategoryChip and ChipRail

A capsule carrying the category icon and name. `surfaceRaised` with a `border`
stroke unselected, `accent` with `contentOnInverse` type selected. The rail
scrolls horizontally and bleeds past the page margin. Chips filter; they never
navigate.

The capsule itself is `chipFace`, so the Pantry Items on Pantry Search wear the
same one without pretending to be categories.

### PromoCard

Full-bleed `surfaceInverse` panel at `promo` radius, `display` heading in
`contentOnInverse`, subcopy at 70% opacity, and a `cream` capsule button.

### MetaLabel

An SF Symbol and a `meta` string in `contentSecondary`. Cook time, calories,
counts.

### CircleIconButton

46×46 `surfaceRaised` square at `control` radius with a `border` stroke, holding
one symbol in `contentPrimary`.

### GreetingBar

Avatar, greeting, and trailing controls. The avatar is a monogram on a category
tint and always opens settings, signed in or out.

### SectionHeader

A `sectionTitle` heading with an optional trailing action in `accent`.

### Buttons

`primary` is `contentOnInverse` on a `surfaceInverse` capsule; `secondary` is
`contentPrimary` on a `cream` capsule; `text` is a bare `label` in `accent`. All
three dim when disabled rather than swapping to a second set of colors.

### EmptyState

Centred symbol, a `sectionTitle` line, a `body` line, and an optional action.
Used by an empty cookbook and by signed-out states.

### SegmentedControl

The existing `CustomSegmentedControl`, restyled onto the tokens.

### SelectionIndicator

The circle that fills when a row or a tile is picked: `accent` filled when picked,
a `contentSecondary` outline when not. Decorative — the row's own text is its
label — so the picked state is announced by the `.isSelected` trait rather than
by a second string read after the name. `onThumbnail` gives it the `surface`
ground it needs over a photo.

### ListRowCard

A named thing on a `surfaceRaised` card at `card` radius, with a `destructive`
control that removes it. The rows of a Meal Plan Day and the Shopping Lists on
Shop. The remove control is a `Button` beside the card rather than inside it: a
button nested in another button does not reliably take its own taps.

### FormField

A labelled control on the writing screens — the label in `label`, the message a
required field shows when it is empty, and `fieldSurface` under the control. A
field in error takes the `destructive` stroke and nothing else changes, so the
value stays readable while it is being corrected.

`fieldSurface` is on offer separately, for the rows of a repeating field that
share one label above them.

## Dynamic Type

Recipe grids are two columns and collapse to one at `.accessibility1` and above,
read from `@Environment(\.dynamicTypeSize)`. `GridItem(.adaptive(minimum:))` does
not solve this — it responds to container width, which does not change when text
grows. `RecipeGrid` holds the rule so no screen restates it.

## Migration

`Extensions/Color.swift`'s coral, slate and teal palette is deleted rather than
redefined — those names describe a system that no longer exists — but it is
deleted **last**, by expand–contract:

1. **Expand.** The token layer lands beside the old palette. Nothing breaks.
2. **Migrate.** One screen group at a time onto the tokens. Unconverted screens
   still compile, because the old palette is still there, so the suite stays
   green after every step.
3. **Contract.** The old palette is deleted once nothing references it, and the
   compiler proves the migration finished.

Deleting first would leave the build red across the whole project, and a suite
that cannot run is a suite that cannot catch a conversion mistake.
