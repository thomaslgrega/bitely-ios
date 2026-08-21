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
