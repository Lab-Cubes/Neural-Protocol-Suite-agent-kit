#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

STATE="$TMP/state"
REPO="$TMP/repo"
mkdir -p "$STATE" "$REPO"

git init "$REPO" -b main >/dev/null
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name "Test User"
printf 'hello\n' > "$REPO/README.md"
git -C "$REPO" add .
git -C "$REPO" commit -m "initial" >/dev/null

NPS_STATE_HOME="$STATE" "$ROOT/bin/agent-kit" setup coder-01 coder >/dev/null
NPS_STATE_HOME="$STATE" "$ROOT/bin/agent-kit" dispatch coder-01 "Smoke task" --scope "$REPO" >/dev/null

result_file="$(find "$STATE/agents/coder-01/done" -maxdepth 1 -name '*.result.json' -print | head -1)"
intent_file="$(find "$STATE/agents/coder-01/done" -maxdepth 1 -name '*.intent.json' -print | head -1)"
branch_file="$(find "$STATE/agents/coder-01/done" -maxdepth 1 -name '*.branch.json' -print | head -1)"

[[ -f "$result_file" ]] || { echo "missing result file" >&2; exit 1; }
[[ -f "$intent_file" ]] || { echo "missing archived intent file" >&2; exit 1; }
[[ -f "$branch_file" ]] || { echo "missing branch metadata" >&2; exit 1; }

"$ROOT/bin/agent-kit" validate-result "$result_file" >/dev/null

python3 - "$intent_file" "$result_file" "$branch_file" "$REPO" <<'PY'
import json
import os
import sys

intent = json.load(open(sys.argv[1]))
result = json.load(open(sys.argv[2]))
meta = json.load(open(sys.argv[3]))
repo = os.path.realpath(sys.argv[4])
assert intent["frame"] == "0x41", intent
assert intent["delegated_scope"]["actions"] == ["nwp://local.agent-kit/execute"], intent
assert result["frame"] == "0x43", result
assert result["is_final"] is True, result
assert os.path.realpath(meta["git_root"]) == repo, meta
assert os.path.isdir(meta["worktree"]), meta
assert meta["branch"].startswith("agent/coder-01/"), meta
assert os.path.realpath(meta["original_scope"]) == repo, meta
assert os.path.realpath(meta["mapped_scope"]) == os.path.realpath(meta["worktree"]), meta
PY

FAIL_STATE="$TMP/fail-state"
NPS_STATE_HOME="$FAIL_STATE" "$ROOT/bin/agent-kit" setup coder-01 coder >/dev/null
set +e
no_claim_output="$(
  NPS_STATE_HOME="$FAIL_STATE" \
  NPS_AGENT_RUNTIME_CMD="$ROOT/scripts/runtime/no-claim.sh" \
  "$ROOT/bin/agent-kit" dispatch coder-01 "No lifecycle task" --scope "$REPO" 2>&1
)"
no_claim_status=$?
set -e
[[ "$no_claim_status" -ne 0 ]] || { echo "no-claim dispatch unexpectedly succeeded" >&2; exit 1; }
printf '%s\n' "$no_claim_output" | grep -q "KIT-DISPATCH-NO-LIFECYCLE"
find "$FAIL_STATE/agents/coder-01/done" -maxdepth 1 -name '*.unclaimed.intent.json' | grep -q .
! find "$FAIL_STATE/agents/coder-01/done" -maxdepth 1 -name '*.result.json' | grep -q .

echo "smoke-test: ok"
