---
status: accepted
---

# Sharing is fail-closed, outlives its screen, and reports failure as Recipe state

`bitelyapi` ADR-0006 puts the image upload on the client: the API mints a presigned
PUT, the client sends the bytes straight to R2, and the share names the staged key.
That makes sharing three sequential round trips instead of one, against a free-tier
instance whose cold start is tens of seconds. This records how the app carries that.

Sharing moves out of `RecipeInfoContentView` into `Cookbook`. A share that fails at
any of the three steps leaves the Recipe Private. While one is in flight the Share
button says so and the screen stays usable; a failure becomes a state on that Recipe
for the rest of the session, offering a retry — or the auth sheet, when the cause was
a 401. The local Recipe keeps its own bytes and records the returned `image_url`
beside them.

## Considered options

**Blocking the detail screen until the share resolves** is the honest reading of
three sequential requests, and it makes the failure trivially reportable: an alert,
while the user is still looking. It also holds someone on one screen for a cold
start they cannot see the reason for.

**Fire and forget** is what the code did — an unstructured `Task` in a view method
and a `print` on the failure path. The share survived dismissal by accident rather
than by design, and its result had nowhere to land.

**Sharing anyway when only the image failed** keeps the user's stated intent, which
is the better trade in most apps. Not this one: the app has no `PUT` path
([#57](https://github.com/thomaslgrega/bitely-ios/issues/57)), so a Shared Recipe
that publishes without its photo cannot be given one, and the corpus is public.
Fail-closed leaves the fixable state on the device.

**A toast or banner** is the usual home for an ambient failure. There is none in this
app, and building one to report this would be a design-system decision made by a
networking change. A state on the Recipe is also the more durable of the two: the
user finds it when they next look at the Recipe, rather than having to be watching.

**Persisting that state** would survive a relaunch, at the cost of a `@Model`
property that is really UI bookkeeping plus a resume path. Session-only says the
truthful thing after a kill — the Recipe is still Private, nothing was shared.

**Dropping the local bytes once R2 holds them** reclaims a few hundred KB and gives
up an offline detail screen. Keeping both also covers the Recipe authored on another
device, which this device has a URL for and no bytes.

## Consequences

A share interrupted by the system suspending the app is forgotten rather than
resumed. The Recipe is Private, which is accurate, and the user's intent to share is
lost silently.

`Cookbook` gains a second in-flight set beside `saving`, and with it a second reason
to be the object that outlives a view. It is now where every Recipe mutation that
crosses the network lives.

Because the encoder runs when a photo is picked rather than when one is shared, the
device's own copy is 800px too. Every Recipe pays for a decision only shared ones
need — and every Recipe stops storing multi-megabyte blobs in SwiftData for it.

A share is taken from a snapshot made before its first suspension: the fields, the
photo and the session. The Recipe stays editable and the account can change while the
upload runs, and either read afterwards publishes something the user never confirmed —
an account that changes mid-share abandons it rather than filing one user's Recipe
under another's name.

Photos picked before the encoder existed are stored full-resolution and survive an app
update, so a share puts the stored bytes back through the encoder and keeps the result.
Without it those Recipes meet the presign's size gate on every retry and can never be
shared.

The failed state is keyed by local Recipe id and lives in memory, so it is invisible
to `@Query` and cannot be observed by a view that only holds a `Recipe`. Views read
it through `Cookbook`, the way they already ask `offersSaving(of:)`.
