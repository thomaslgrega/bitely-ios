#!/bin/bash
# PostToolUse hook: hand a freshly-created PR to Codex for review.
# Reads the hook payload on stdin, finds the PR number, detaches a codex run.
set -uo pipefail

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG_DIR="$PROJECT_DIR/.claude/hooks/logs"
mkdir -p "$LOG_DIR"

payload=$(cat)

# The PR URL is in stdout for `gh pr create` and in the result body for the MCP tool.
pr=$(printf '%s' "$payload" | grep -oE 'github\.com/[^"[:space:]]+/pull/[0-9]+' | head -1 | grep -oE '[0-9]+$')
[ -z "$pr" ] && pr=$(printf '%s' "$payload" | jq -r '.tool_response.number // empty' 2>/dev/null)
[ -z "$pr" ] && pr=$(cd "$PROJECT_DIR" && gh pr view --json number -q .number 2>/dev/null)
[ -z "$pr" ] && exit 0

# One review per PR, even if several tool calls look like a creation.
lock="$LOG_DIR/.reviewed-$pr"
[ -e "$lock" ] && exit 0
: > "$lock"

repo=$(cd "$PROJECT_DIR" && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)

PROMPT="/code-review PR #$pr of $repo.

Establish the change set without touching the working tree — do not check out, switch, stash, or reset anything:

  gh pr view $pr --json baseRefName,baseRefOid,headRefOid,title,body
  git fetch origin pull/$pr/head
  git diff <baseRefOid>...<headRefOid>

Use <baseRefOid> as the fixed point.

When the review is finished, post it as a single comment on the PR:

  gh pr comment $pr --repo $repo --body-file <path to a file you write>

Post exactly one comment. Lead with a one-line verdict, then the findings ordered most severe first, each naming file and line. If nothing is worth acting on, say so in the comment rather than posting nothing. Do not commit, push, edit repository files, approve, request changes, or merge."

nohup codex exec \
  -C "$PROJECT_DIR" \
  -s workspace-write \
  -c sandbox_workspace_write.network_access=true \
  "$PROMPT" \
  >"$LOG_DIR/pr-$pr.log" 2>&1 &

echo "{\"systemMessage\": \"Codex review of PR #$pr started (log: .claude/hooks/logs/pr-$pr.log)\"}"
