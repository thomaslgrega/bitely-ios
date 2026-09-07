---
status: accepted
---

# Edits to an authored Shared Recipe are local-first with a persisted pending push

`Cookbook.commit` writes to the `ModelContext` and nothing reaches the API, so a user who
edits a Recipe they authored and shared leaves the corpus serving the old one. `bitelyapi`
ADR-0006 settles the wire shape this needs and owns it.

The local write is authoritative and always succeeds. The push to the corpus is
best-effort, and what it leaves behind when it fails is an **Unshared Edit**: two flags on
the Recipe, one per leg of the push, cleared by the response that lands each leg. The
branch is authorship — `Cookbook.segment(for:)` — so editing a Saved Recipe stays local
forever, because it is someone else's work.

Every push reads the Recipe as it stands when it runs. A retry therefore carries the
newest state rather than replaying the edit that failed, and three failed edits collapse
into one correct push.

## Considered options

**Fail-closed, as sharing is.** Sharing can refuse to publish because nothing has happened
yet. An edit has already been typed and committed by the time any request is made, so the
equivalent is discarding the user's work on their own device because a free-tier instance
was cold.

**Blocking the save until the round trip resolves** makes the failure trivially reportable
while the user is still looking at the form. It also holds them on that form for a cold
start they cannot see the reason for.

**Failing silently** keeps the code small and publishes a lie: the corpus is public, and
nothing on the device would say the two disagree.

**Session-only state, as ADR-0002 chose for sharing.** That ADR justified forgetting on the
grounds that the truthful answer after a kill is *nothing was shared*. Here the truthful
answer is *the corpus is stale*, and only a persisted flag can say it. Session-only would
make the drift visible for one session and invisible forever after.

**An outbox** — queued mutations with ordering and conflict resolution — is a sync model,
and would earn its own ADR if it were ever wanted. Nothing here queues: the flags say the
device is ahead, and the next push makes the corpus match.

**One flag rather than two.** A save is written in the order `bitelyapi` ADR-0006 sets, so
the common failure leaves one leg landed and the other not. A single flag would re-run both
on retry: a second transfer of the same bytes, and an orphaned object in the bucket. Two
flags cost one `@Model` property.

**Storing the staged key instead of a second flag** would let a retry skip the upload it
already did. The presigned URL expires in five minutes and any retry worth having is later
than that.

## Consequences

A Recipe carries two `Bool`s that are about the corpus rather than about the Recipe. They
are on the model and not in `Cookbook` because that is what makes them survive a kill, which
is the whole point of the decision above.

An edit made while signed out sets no flag and makes no request. Authorship is
session-scoped, so signed out the device cannot tell this user's own Shared Recipe from one
they saved, and optimistically flagging every Recipe with a remote id would send doomed
writes for other people's work.

`Cookbook`'s in-flight map is now where any write to the corpus reports itself, share or
push. A Recipe is Private or Shared and never both, so one map serves both without them
ever meeting.

A push in flight does not block a save. The save re-marks the flags and the running push
loops, so the last edit reaches the corpus without the user touching anything.

A flag is cleared only once the response that lands its leg has arrived, never before it,
so an app killed mid-push still finds the edit recorded on the next launch. Telling a save
made during a push from the one the push is carrying therefore needs a second signal, and
that is a transient generation count: it orders one session's writes, and a launch that has
forgotten it is a launch where the durable flags are the whole truth anyway.

A pending edit belongs to the account that made it. Signing in as someone else files that
Recipe under Saved, and a Saved Recipe neither sends nor offers a retry — so the edit waits
rather than going up under the wrong name, and comes back when its author returns.

The detail screen retries on appearance. That is the one place the state is visible and the
one place the edit was made from, so nothing sweeps the store and nothing observes the
scene phase.

The Recipe's `imageURL` is rewritten from what the image write answers rather than from a
later read, per `bitelyapi` ADR-0006.
