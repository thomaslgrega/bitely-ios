# App flow

Where every piece of Bitely lives after the redesign. Vocabulary is
[`CONTEXT.md`](../../CONTEXT.md) and the API's glossary; the visual system is
[design-system.md](./design-system.md).

Five tabs become four. Nothing is dropped — the Shared tab merges into the
Cookbook, split by authorship rather than by storage.

## Discover

The front door. Browsing and Pantry Search.

**Greeting bar.** Avatar, greeting, no search button. The name falls back
`firstName` → the local part of `email` → "Welcome to Bitely", so the bar reads
the same shape signed in, signed in without a name, and signed out. The avatar
opens settings in every state.

**Pantry promo.** A `PromoCard` into Pantry Search. It gets the screen's largest
element: it is the app's most distinctive feature and the only one that works
with no network and no account.

**Chip rail.** One `CategoryChip` per Category, filtering in place. Chips never
navigate — there is no pushed category screen, no "View all", and no long-press.
`RecipeListView.swift` is deleted.

**Today's Picks.** A grid of `RecipeTile`s, seeded by the date so it is stable
within a day and changes daily. Selecting a chip swaps the heading to the
Category and the grid to that Category's Recipes.

### Where the Recipes come from

The API serves `recipes?category=`, and nothing else that returns a feed. So on
first open the app fans out across all ten Categories in parallel and holds the
result for the session. Categories that fill the first screen are requested
first and the grid paints as they land.

The chips then cost nothing: they filter a store that already holds every
Category completely. This is the point of the fan-out. The alternative — filter
only what a small merged feed happened to load — shows two Recipes under
Seafood and gives the user no way to tell whether that is the filter or the
catalogue.

The store lives for the session and is refetched on cold launch. Ten small
parallel requests on launch is fewer than the app makes today, where every
category push refetches with no cache.

**This does not scale.** Once the corpus outgrows a few hundred Recipes the
fan-out stops being viable and the API needs a real feed endpoint. That is
filed; the view does not change when it lands.

## Cookbook

Everything on the device, split by **authorship**, because that is how the
domain splits.

| Segment | Holds | Source |
| --- | --- | --- |
| **My Recipes** | Private Recipes, plus the Shared Recipes this user authored | Local store + `me/recipes` |
| **Saved** | Other people's Shared Recipes kept locally | Local store |

**Creating.** One `+`, on My Recipes, always making a Private Recipe. It never
publishes and never asks about publishing, so there is no way to share something
by accident.

**Sharing** is a separate, deliberate action on a Recipe's detail screen, and it
is offered only on a Private Recipe. A Saved Recipe is someone else's work and
cannot be re-shared under this user's name. Signed out, the action presents the
auth sheet at the moment of sharing, where the intent is unambiguous and there is
no half-filled form to lose. Switching segments never presents a sheet.

**Editing** is local and available on every Recipe in the Cookbook regardless of
who authored it. Adding salt or raising the oven temperature on a Saved Recipe
writes to the local copy only and never reaches the API — which is why gating
sharing costs the user nothing.

**Unsaving** always confirms. It deletes a local Recipe whose Ingredients and
instructions may have been edited, and the new control is a heart, light enough
that a silent second tap would be destructive.

## Plan

Today's Calendar, restyled. A Meal Plan Day per date, Recipes slotted by Meal
Type, added from a Recipe's detail screen.

## Shop

Today's Shopping List tab, restyled. Lists written by hand or generated from a
Recipe's Ingredients; a generated list is independent of the Recipe once made.

## Settings and auth

Out of the toolbar and onto Discover's avatar. Account, sign in, sign out.

Auth gates one thing: sharing a Recipe. Browsing, Pantry Search, saving,
creating, editing, planning and shopping all work signed out, so nothing else
prompts for an account.

## Order of work

Expand, migrate, contract — so the suite is green at every step.

1. **Expand**: the token layer, beside the existing palette.
2. Components, against the design system doc.
3. Discover, including the fan-out store.
4. Cookbook, including the segment split and the sharing action.
5. Plan, Shop, recipe detail and Pantry Search.
6. The tab bar, settings and the auth entry.
7. **Contract**: delete the old palette and the redesign mocks.

All four tabs convert on one branch before merge. Two visual systems in one
shipped build reads as a bug — but that is a rule about what ships, not about
what compiles: steps 2 through 6 each leave a working app.
