# Bitely iOS

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `thomaslgrega/bitely-ios` (https://github.com/thomaslgrega/bitely-ios/issues), via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

### Shared domain docs (backend repo)

The recipe and ingredient glossary, the matching algorithm spec, and the ADRs
covering them live in the backend repo, `thomaslgrega/bitelyapi`. The backend
owns these definitions. Read them before working on anything that crosses the
API boundary, and don't restate them locally — a second copy drifts.

```sh
gh api repos/thomaslgrega/bitelyapi/contents/CONTEXT.md --jq .content | base64 -d
gh api repos/thomaslgrega/bitelyapi/contents/docs/ingredient-matching-algorithm.md --jq .content | base64 -d
gh api repos/thomaslgrega/bitelyapi/contents/docs/adr --jq '.[].name'
```

`CONTEXT.md` at this repo root, when it exists, covers iOS-only concepts (local
store, presentation state). Anything shared with the API belongs in the backend
copy.

## Commits

Commit only when the user asks for it in that turn. Otherwise leave the work uncommitted for them to review.

## TDD

Every change goes red → green, and the red step is not optional. Skipping straight to implementation is the one failure mode this rule exists to stop.

1. **Red.** Write tests that capture the desired behaviour, run them, and confirm they fail for the reason you expect. For a bug, the failing test reproduces the bug.
2. **Green.** Write the implementation that makes those tests pass.
3. **Verify.** Run the suite and confirm it is clean before reporting the work done:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild test -project Bitely.xcodeproj -scheme Bitely \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Report step 3's actual output. A suite you did not run is not green.

### Writing tests

- **Swift Testing**, not XCTest: `@Suite` / `@Test` / `#expect` / `try #require`. Cases that
  vary only by input go through `@Test(arguments:)` rather than a copied function.
- Tests run **in parallel**. Give each test its own state — no `UserDefaults.standard`, no
  static mutable fixtures, no registered `URLProtocol`.
- Add a test file by dropping it in `BitelyTests/`. That folder is a synchronized group, so
  it joins the target on its own; editing `project.pbxproj` by hand is how the target got
  broken once already.

### Seams

Collaborators are injected with a working default, so the app wires itself up and tests
substitute:

- `APIClient(authStore:transport:)` takes an `HTTPTransport`. Tests pass `StubTransport`,
  which answers from a canned closure and records requests — `httpBody` included.
- `AuthStore(defaults:)` takes a `UserDefaults`. Tests pass `makeIsolatedDefaults()`.

Reach for the same pattern when new code needs the network, the clock, or the disk.

### xcodebuild gotchas

- `xcode-select` on this machine points at `CommandLineTools`, so a bare `xcodebuild`
  fails. Set `DEVELOPER_DIR` as above.
- A simulator name that exists under two installed runtimes (e.g. `iPhone 15`) is an
  ambiguous destination and errors out instead of picking one. `iPhone 17` resolves.
