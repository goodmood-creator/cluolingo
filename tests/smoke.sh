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

# 5. ask + case-insensitive answer scores correct, streak=1, pending queue emptied
"$CLUO" ask "pagination" "x" "split into pages = p___" >/dev/null
ANS="$("$CLUO" answer "Pagination")"
printf '%s' "$ANS" | grep -q "correct" || fail "answer should be graded correct"
STREAK="$(jq -r '.streak' "$SANDBOX/cluolingo/state.json")"
[ "$STREAK" = "1" ] || fail "streak should be 1 (got: $STREAK)"
PCOUNT="$(jq -r '.pending | length' "$SANDBOX/cluolingo/state.json")"
[ "$PCOUNT" = "0" ] || fail "pending queue should be empty (got length: $PCOUNT)"

# 6. queue: two questions don't clobber; LIFO answers the most recent
# (capture output into a var before grep — piping cluo into `grep -q` would close
#  the pipe early and SIGPIPE cluo, which `pipefail` then misreports as failure)
"$CLUO" ask "alpha" "first" "q1" >/dev/null
"$CLUO" ask "beta" "second" "q2" >/dev/null
[ "$(jq -r '.pending | length' "$SANDBOX/cluolingo/state.json")" = "2" ] || fail "queue should hold 2 questions"
A1="$("$CLUO" answer "beta")"
printf '%s' "$A1" | grep -q "correct" || fail "LIFO should grade the most recent (beta)"
[ "$(jq -r '.pending | length' "$SANDBOX/cluolingo/state.json")" = "1" ] || fail "one question should remain after answering"
A2="$("$CLUO" answer "alpha")"
printf '%s' "$A2" | grep -q "correct" || fail "remaining question (alpha) should grade correct"

# 7. session scoping: a session answers ITS question, not another session's newer one
"$CLUO" reset >/dev/null
CLAUDE_CODE_SESSION_ID="sessA" "$CLUO" ask "apple" "x" "qA" >/dev/null
CLAUDE_CODE_SESSION_ID="sessB" "$CLUO" ask "banana" "x" "qB" >/dev/null
A7="$(CLAUDE_CODE_SESSION_ID="sessA" "$CLUO" answer "apple")"
printf '%s' "$A7" | grep -q "correct" || fail "session A must grade its own question (apple), not session B's newer one"
[ "$(jq -r '.pending | length' "$SANDBOX/cluolingo/state.json")" = "1" ] || fail "session B's question must remain pending"
[ "$(jq -r '.pending[0].answer' "$SANDBOX/cluolingo/state.json")" = "banana" ] || fail "the remaining question must be session B's (banana)"
A7B="$(CLAUDE_CODE_SESSION_ID="sessB" "$CLUO" answer "banana")"
printf '%s' "$A7B" | grep -q "correct" || fail "session B must grade its own question (banana)"

# 8. a session must NOT answer another session's question when it has none of its own
"$CLUO" reset >/dev/null
CLAUDE_CODE_SESSION_ID="sessB" "$CLUO" ask "cherry" "x" "qC" >/dev/null
A8="$(CLAUDE_CODE_SESSION_ID="sessA" "$CLUO" answer "cherry")"
printf '%s' "$A8" | grep -q "no pending question for you" || fail "session A must not see session B's question"
[ "$(jq -r '.pending | length' "$SANDBOX/cluolingo/state.json")" = "1" ] || fail "session B's question must stay pending"

# 9. legacy untagged questions stay answerable by any session (backward compat)
"$CLUO" reset >/dev/null
jq '.pending = [{answer:"legacy", explain:"x", q:"qL"}]' "$SANDBOX/cluolingo/state.json" > "$SANDBOX/_t.json" && mv "$SANDBOX/_t.json" "$SANDBOX/cluolingo/state.json"
A9="$(CLAUDE_CODE_SESSION_ID="sessZ" "$CLUO" answer "legacy")"
printf '%s' "$A9" | grep -q "correct" || fail "legacy untagged question must be answerable by any session"

echo "ok: all smoke checks passed"
exit 0
