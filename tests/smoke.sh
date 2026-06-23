#!/usr/bin/env bash
# cluolingo :: smoke test
# Runs every check against a throwaway CLAUDE_CONFIG_DIR sandbox.
# All green -> exit 0 ; any failure -> print which one and exit 1.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUO="$ROOT/scripts/cluo"
HOOK="$ROOT/hooks/cluolingo.sh"

command -v jq >/dev/null 2>&1 || { echo "smoke: jq is required"; exit 1; }

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
export CLAUDE_CONFIG_DIR="$SANDBOX"

fail() { echo "FAIL: $1"; exit 1; }

# 1. syntax check
bash -n "$CLUO" || fail "bash -n scripts/cluo"
bash -n "$HOOK" || fail "bash -n hooks/cluolingo.sh"

# 2. hook injects valid JSON with both markers
OUT="$(printf '%s' '{"prompt":"做個功能"}' | bash "$HOOK")"
printf '%s' "$OUT" | jq -e . >/dev/null 2>&1 || fail "hook output is not valid JSON"
CTX="$(printf '%s' "$OUT" | jq -r '.hookSpecificOutput.additionalContext')"
printf '%s' "$CTX" | grep -q "English version" || fail 'additionalContext missing "English version"'
printf '%s' "$CTX" | grep -q "CLUOLINGO MODE" || fail 'additionalContext missing "CLUOLINGO MODE"'

# 3. "!"-prefixed prompts are escaped (zero output)
OUT="$(printf '%s' '{"prompt":"! cluo stats"}' | bash "$HOOK")"
[ -z "$OUT" ] || fail "escape: !-prefixed prompt should produce no output"

# 4. disabled -> fail-open (zero output); re-enabling restores injection
"$CLUO" off >/dev/null
OUT="$(printf '%s' '{"prompt":"做個功能"}' | bash "$HOOK")"
[ -z "$OUT" ] || fail "disabled hook should produce no output"
"$CLUO" on >/dev/null
OUT="$(printf '%s' '{"prompt":"做個功能"}' | bash "$HOOK")"
[ -n "$OUT" ] || fail "re-enabled hook should inject again"

# 5. ask + case-insensitive answer scores correct, streak=1, pending cleared
"$CLUO" ask "pagination" "x" >/dev/null
ANS="$("$CLUO" answer "Pagination")"
printf '%s' "$ANS" | grep -q "correct" || fail "answer should be graded correct"
STREAK="$(jq -r '.streak' "$SANDBOX/cluolingo/state.json")"
[ "$STREAK" = "1" ] || fail "streak should be 1 (got: $STREAK)"
PENDING="$(jq -r '.pending' "$SANDBOX/cluolingo/state.json")"
[ "$PENDING" = "null" ] || fail "pending should be cleared (got: $PENDING)"

echo "ok: all smoke checks passed"
exit 0
