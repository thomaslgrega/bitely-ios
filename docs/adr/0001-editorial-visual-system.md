---
status: accepted
---

# A two-layer token system, structured for dark mode, shipped light-only

Bitely's coral/slate/teal palette is replaced wholesale by the Editorial Feed
direction — cream, ink and brick red, set in Fraunces — across all five tabs in
one cutover. Colors are defined twice: a private brand palette that names the
values, and public role tokens (`surface`, `contentPrimary`, `accent`, `border`)
that views reference. Both light and dark appearances are filled in the asset
catalog now, while `BitelyApp` keeps its `.preferredColorScheme(.light)` pin.
The tokens and components are catalogued in
[docs/design/design-system.md](../design/design-system.md).

## Considered options

**Redefining `Color.primaryMain` and friends in place** would have avoided
touching call sites, at the cost of leaving `secondary50` meaning "cream"
forever. They are deleted instead — but by expand–contract, with the deletion
last, so the suite stays green through every migration step. Deleting first
would have made the compiler the migration checklist at the price of a build
that cannot run its tests for the length of the project.

**Brand-named tokens** (`cream`, `ink`, `red`) were the mock's approach and read
well until dark mode, where `cream` stops being cream. Role names survive the
inversion; the brand layer keeps the values greppable underneath.

**Shipping without dark structure** was the cheaper option today. Retrofitting
dark onto flat constants means touching every token *and* every call site a
second time, whereas filling a second column in an asset catalog costs one pass
now.

**A `Theme` struct in the environment** is the right shape for a white-label app.
Bitely has one brand, so it would force a theme parameter through every component
in exchange for flexibility that will not be used.

## Consequences

Fraunces sizes go through `Font.custom(_:size:relativeTo:)`, so type scales with
Dynamic Type. That makes fixed-height cards untenable: recipe tiles become
intrinsically sized and recipe grids drop to a single column at `.accessibility1`
and above.

Recipes carry photos, but not all of them, so every grid mixes photography with
the category-tint fallback. The fallback is a designed state — matching radius,
matching border, a warm overlay on photos — not an absent image. This is the part
of the system most likely to need revisiting once it is seen against real API
data rather than the mock, which looks good partly because it contains no
photographs at all.
