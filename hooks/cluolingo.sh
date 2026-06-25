#!/usr/bin/env bash
# cluolingo :: UserPromptSubmit hook  (Claude × Duolingo)
# Runs the real task in the background and slips a casual "by the way" language
# quiz into the foreground. Multi-language. NEVER blocks execution (fail-open).
set -euo pipefail

CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STATE_DIR="$CONFIG_DIR/cluolingo"
STATE_FILE="$STATE_DIR/state.json"

# --- fail-open: if jq is missing, do nothing rather than break the prompt ---
command -v jq >/dev/null 2>&1 || { exit 0; }

# --- read the hook payload (UserPromptSubmit gives {prompt, ...}) ---
PAYLOAD="$(cat 2>/dev/null || true)"
PROMPT="$(printf '%s' "$PAYLOAD" | jq -r '.prompt // empty' 2>/dev/null || true)"

# --- escape hatch: shell commands (prompts starting with "!") are never touched ---
case "$PROMPT" in
  "!"*) exit 0 ;;
esac

# --- load or seed state ---
mkdir -p "$STATE_DIR"
if [ ! -f "$STATE_FILE" ]; then
  cat > "$STATE_FILE" <<'JSON'
{
  "enabled": true,
  "mode": "every",
  "freq": 5,
  "chance": 30,
  "target_lang": "English",
  "native_lang": "Chinese",
  "prompt_count": 0,
  "quiz_count": 0,
  "correct": 0,
  "streak": 0,
  "best_streak": 0,
  "pending": [],
  "words_seen": []
}
JSON
fi

# NOTE: jq's `//` treats false as empty, so `.enabled // true` would read false as
# true. Read the raw value and only bail when it is explicitly "false".
ENABLED="$(jq -r '.enabled' "$STATE_FILE" 2>/dev/null || echo true)"
[ "$ENABLED" = "false" ] && exit 0   # disabled -> fail-open, no injection

MODE="$(jq -r '.mode // "every"' "$STATE_FILE")"
FREQ="$(jq -r '.freq // 5' "$STATE_FILE")"
CHANCE="$(jq -r '.chance // 30' "$STATE_FILE")"
TARGET="$(jq -r '.target_lang // "English"' "$STATE_FILE")"
NATIVE="$(jq -r '.native_lang // "Chinese"' "$STATE_FILE")"
COUNT="$(jq -r '.prompt_count // 0' "$STATE_FILE")"
COUNT=$((COUNT + 1))

# --- persist incremented counter atomically ---
TMP="$(mktemp "$STATE_DIR/.state.XXXXXX")"
jq --argjson c "$COUNT" '.prompt_count = $c' "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"

# --- decide whether a quiz is due this turn ---
should_trigger() {
  case "$MODE" in
    every) return 0 ;;
    freq)  [ "$FREQ" -gt 0 ] && [ $((COUNT % FREQ)) -eq 0 ] && return 0 ; return 1 ;;
    chance) [ $((RANDOM % 100)) -lt "$CHANCE" ] && return 0 ; return 1 ;;
    *) return 0 ;;
  esac
}

# --- base instruction (always on); __TARGET__/__NATIVE__ filled in below ---
read -r -d '' BASE <<'TXT' || true
You are running with **Cluolingo** (Claude × Duolingo), a non-blocking language-practice companion. The user's target practice language is __TARGET__ and their native language is __NATIVE__.
BEFORE answering, output a "__TARGET__ version" block at the very TOP of your reply, in EXACTLY this shape (keep the section labels in English; put content in the language each line calls for):

**__TARGET__ version**
> a natural, polished __TARGET__ rewrite of the user's request — good enough to use as a prompt on its own, not a literal translation

**Phrasing notes:**
- 2-4 bullets, each "<__NATIVE__ term> → <__TARGET__ term>" with a tiny note on any tricky word

Then continue with the main answer in __NATIVE__, fully addressing the actual request as usual.
Skip this whole block only when the message is trivially short (e.g. "ok", "繼續", "謝謝", "thanks"), a pure clarification question, or the user is answering a pending Cluolingo question.
TXT

# --- quiz + background-dispatch instruction (only when a quiz is due) ---
read -r -d '' GATE <<'TXT' || true

CLUOLINGO MODE IS ACTIVE for this turn. If — and only if — this message is a SUBSTANTIVE task (real work: code changes, research, multi-step), do ALL of the following:
1. Dispatch the actual task to a BACKGROUND agent (Agent tool, or Bash run_in_background for long commands) so the real work proceeds while you talk. Mention in one line what you kicked off.
2. Immediately AFTER the "Phrasing notes" bullets — before the main answer — add a "**Quick quiz:**" section, so it always sits in the same, easy-to-spot place. Give it one or two short, numbered items drawn from the rewrite or the phrasing notes: a fill-in-the-blank, and optionally a multiple-choice. Keep them light; do NOT reveal the answers. EVERY fill-in-the-blank MUST embed a short Chinese cue (and "一個字" when the answer is a single word) in parentheses right after the blank, so it is answerable later with no surrounding context — e.g. `run a ___ test first (冒煙, 一個字)` or `carry it at ___ ends (兩端, 一個字)`. Multiple-choice items don't need a cue since the options supply the context. The question text you pass to `cluo ask` must be this self-contained version (blank + cue), because that is all the user sees when they peek the queue. Register EACH item out-of-band via Bash: `cluo ask "<correct answer>" "<one-line explanation>" "<the question text>"` (pending is a queue, so multiple items and concurrent sessions never clobber each other). Tell the user they can answer with `! cluo answer <their answer>` (zero-token, scored instantly) or just reply in chat — the built-in `/btw` also works for quick feedback, but only `! cluo answer` or a chat reply actually updates the score.
3. NEVER block on it. The moment the background task reports back, surface its result regardless of whether the user answered. The aside is optional practice, never a gate.
4. The user may answer several ways: (a) via `! cluo answer <ans>` — the CLI scores it out-of-band, so you do nothing; (b) by replying in chat — grade it warmly in one line and record it via Bash: `cluo grade correct` or `cluo grade wrong`, plus `cluo word <theword>` for each new vocab item taught; (c) via Claude Code's built-in `/btw <ans>` side note — that runs in a READ-ONLY fork, so just give warm one-line feedback and note you cannot record the score there (they can re-enter it with `! cluo answer` to make it count). If the `cluo` command is not found, skip silently.
For a trivial or quick message, just drop the quick quiz inline (or skip entirely if trivially short) and do not spawn a background agent.
TXT

if should_trigger; then
  CTX="$BASE"$'\n'"$GATE"
else
  CTX="$BASE"
fi

# --- fill in the language placeholders ---
CTX="${CTX//__TARGET__/$TARGET}"
CTX="${CTX//__NATIVE__/$NATIVE}"

jq -nc --arg ctx "$CTX" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
