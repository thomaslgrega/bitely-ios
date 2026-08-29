# App flow

Where every piece of Bitely lives after the redesign. Vocabulary is
[`CONTEXT.md`](../../CONTEXT.md) and the API's glossary; the visual system is
[design-system.md](./design-system.md).

Five tabs become four. Nothing is dropped — the Shared tab merges into the
Cookbook, split by authorship rather than by storage.

## Discover

The front door. Browsing and Pantry Search.

**Greeting bar.** Avatar, greeting, and a search button into Name Search. The name falls back
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

A bare `GET /recipes` answers the Feed — the corpus by recency of sharing,
capped at fifty. The ordering and the cap are the API's, in `bitelyapi`
ADR-0005. Today's Picks rotates within what it returns; that rotation is the
app's business, not the API's.

Chips fetch their Category rather than filtering the Feed. Fifty Recipes
ordered by recency filtered to Seafood shows however many of the newest fifty
happen to be seafood, and gives the user no way to tell whether that is the
filter or the catalogue. `recipes?category=` answers everything it finds, so a
chip always shows its Category completely.

The store lives for the session: the Feed once on cold launch, then at most one
request per Category the user actually taps, each cached until relaunch.

### Name Search

A pushed screen off the greeting bar's search button, titled "Find a recipe".
Type a name, get matching Shared Recipes as a grid of the same savable tiles
Today's Picks draws. It is reached the way Pantry Search is, so the two are
structurally siblings; their entry points differ in weight because they answer
different questions, and Pantry Search keeps the promo card.

Every query is `GET /recipes?name=` — the match is fuzzy and the order is
closest-first, both the API's (`bitelyapi` ADR-0004), so a misspelling still
lands and the grid sorts nothing. Filtering the Feed instead would miss exactly
the Recipe the user came for. The Category selection on Discover underneath is
untouched and never narrows a Name Query.

Results arrive as the user types: 300ms after the last keystroke, from two
characters up, one query at a time. Nothing typed is the prompt state; a query
that matches nothing names itself back to the user; a failure offers a retry
that re-runs the same query. Nothing is cached — free text is not the small
closed set the Feed and the Categories are.

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

**Filtering** is a local filter over the open segment, in a field below the
segments — the position states the scope, where a field above them would read as
filtering the whole Cookbook. Both segments already hold everything they show,
so nothing is fetched and nothing can fail. The query is tokenized on
whitespace and every token must appear in the name, ignoring case and accents,
which makes word order irrelevant and leaves the match deliberately not fuzzy:
the typo that finds a Shared Recipe on Discover finds nothing here. An empty
field shows the whole segment, and a segment holding nothing shows no field at
all. When a query matches nothing here but something in the other segment, the
empty state says how many and offers the switch, so a correct spelling is never
a dead end.

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
3. Discover, including the session Recipe store.
4. Cookbook, including the segment split and the sharing action.
5. Plan, Shop, recipe detail and Pantry Search.
6. The tab bar, settings and the auth entry.
7. **Contract**: delete the old palette and the redesign mocks.

All four tabs convert on one branch before merge. Two visual systems in one
shipped build reads as a bug — but that is a rule about what ships, not about
what compiles: steps 2 through 6 each leave a working app.
