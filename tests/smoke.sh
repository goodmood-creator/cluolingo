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

# 6b. @N selector answers a SPECIFIC open question (oldest first), not just the newest
"$CLUO" reset >/dev/null
"$CLUO" ask "alpha" "first/oldest" "q1" >/dev/null
"$CLUO" ask "beta"  "second"       "q2" >/dev/null
"$CLUO" ask "gamma" "third/newest" "q3" >/dev/null
A6B="$("$CLUO" answer @1 alpha)"   # @1 = oldest, newest-last numbering
printf '%s' "$A6B" | grep -q "correct" || fail "@1 should grade the oldest question (alpha)"
[ "$(jq -r '.pending | length' "$SANDBOX/cluolingo/state.json")" = "2" ] || fail "@N answer should pop exactly one question"
[ "$(jq -r '[.pending[].answer] | sort | join(",")' "$SANDBOX/cluolingo/state.json")" = "beta,gamma" ] || fail "@1 must remove the oldest, leaving beta+gamma"
A6BAD="$("$CLUO" answer @9 nope)"  # out-of-range index is rejected, scores nothing
printf '%s' "$A6BAD" | grep -q "no open question @9" || fail "out-of-range @N should be rejected"
[ "$(jq -r '.pending | length' "$SANDBOX/cluolingo/state.json")" = "2" ] || fail "rejected @N must not pop anything"

# 6c. --all drains orphaned backlog cross-session; default scope still can't reach it
"$CLUO" reset >/dev/null
CLAUDE_CODE_SESSION_ID="oldA" "$CLUO" ask "alpha" "fromA" "qA1" >/dev/null
CLAUDE_CODE_SESSION_ID="oldA" "$CLUO" ask "beta"  "fromA" "qA2" >/dev/null
CLAUDE_CODE_SESSION_ID="oldB" "$CLUO" ask "gamma" "fromB" "qB1" >/dev/null
# a fresh session has nothing of its own → session-scoped answer sees nothing
A6C0="$(CLAUDE_CODE_SESSION_ID="newC" "$CLUO" answer "alpha")"
printf '%s' "$A6C0" | grep -q "no pending question for you" || fail "fresh session must not reach orphaned backlog without --all"
[ "$(jq -r '.pending | length' "$SANDBOX/cluolingo/state.json")" = "3" ] || fail "session-scoped answer must not pop an orphan"
# --all @1 grades the oldest orphan regardless of session
A6C1="$(CLAUDE_CODE_SESSION_ID="newC" "$CLUO" answer --all @1 alpha)"
printf '%s' "$A6C1" | grep -q "correct" || fail "--all @1 should grade the oldest orphan (alpha)"
[ "$(jq -r '[.pending[].answer] | sort | join(",")' "$SANDBOX/cluolingo/state.json")" = "beta,gamma" ] || fail "--all @1 must remove only the oldest orphan"
# out-of-range --all index scores nothing
A6C2="$(CLAUDE_CODE_SESSION_ID="newC" "$CLUO" answer --all @9 nope)"
printf '%s' "$A6C2" | grep -q "no open question @9 anywhere" || fail "out-of-range --all @N should be rejected"
[ "$(jq -r '.pending | length' "$SANDBOX/cluolingo/state.json")" = "2" ] || fail "rejected --all @N must not pop anything"

# 6d. persisted answer_scope=all makes a bare `answer` reach every session; --mine overrides
"$CLUO" reset >/dev/null
CLAUDE_CODE_SESSION_ID="oldA" "$CLUO" ask "alpha" "fromA" "qA1" >/dev/null
CLAUDE_CODE_SESSION_ID="me"   "$CLUO" ask "mine"  "fromMe" "qMine" >/dev/null
"$CLUO" set scope all >/dev/null
[ "$(jq -r '.answer_scope' "$SANDBOX/cluolingo/state.json")" = "all" ] || fail "set scope all should persist"
# under scope=all, a bare (flagless) answer reaches the orphaned question
A6D="$(CLAUDE_CODE_SESSION_ID="me" "$CLUO" answer @1 alpha)"
printf '%s' "$A6D" | grep -q "correct" || fail "scope=all: bare @1 should reach orphaned alpha without --all"
[ "$(jq -r '[.pending[].answer] | join(",")' "$SANDBOX/cluolingo/state.json")" = "mine" ] || fail "scope=all @1 must pop the orphan, leaving mine"
# --mine overrides back to session scope even when default is all
A6DM="$(CLAUDE_CODE_SESSION_ID="me" "$CLUO" answer --mine)"
printf '%s' "$A6DM" | grep -q "qMine" || fail "--mine should limit peek to this session"
"$CLUO" set scope bogus 2>/dev/null && fail "set scope bogus should be rejected"
"$CLUO" set scope session >/dev/null

# 6e. batch @N=ans grades several at once; indices resolve BEFORE any pop (no off-by-one)
"$CLUO" reset >/dev/null
"$CLUO" ask "yourself"     "x" "b1" >/dev/null
"$CLUO" ask "commit"       "x" "b2" >/dev/null
"$CLUO" ask "fix in place" "x" "b3" >/dev/null
"$CLUO" ask "ends"         "x" "b4" >/dev/null
"$CLUO" ask "delegate"     "x" "b5" >/dev/null
# @1 right, @3 right (multi-word, UNQUOTED), @4 wrong, @9 invalid (skipped, uncounted)
A6E="$("$CLUO" answer @1=yourself @3=fix in place @4=wrongo @9=nope)"
printf '%s' "$A6E" | grep -q "3 graded, 2 correct" || fail "batch should grade 3 (skip invalid @9), 2 correct"
printf '%s' "$A6E" | grep -q "no such open question" || fail "batch should report the invalid @9 as skipped"
# the RIGHT three were popped (b1,b3,b4), leaving exactly b2 + b5 — proves pre-resolution
[ "$(jq -r '[.pending[].q] | join(",")' "$SANDBOX/cluolingo/state.json")" = "b2,b5" ] || fail "batch must pop the resolved indices, not shifted ones (expected b2,b5)"
[ "$(jq -r '.quiz_count' "$SANDBOX/cluolingo/state.json")" = "3" ] || fail "batch must count exactly 3 graded (invalid not counted)"
[ "$(jq -r '.correct' "$SANDBOX/cluolingo/state.json")" = "2" ] || fail "batch must count 2 correct"

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
