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
  "pending": null,
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
BEFORE answering, FIRST output a "__TARGET__ version" block at the very top of your reply:
(1) a natural, polished __TARGET__ rewrite of the user request that could itself be used as a prompt (not a literal translation);
(2) 2-4 short __NATIVE__→__TARGET__ phrasing notes for tricky words.
Then continue with the main answer in __NATIVE__, fully addressing the actual request as usual.
Skip this block only when the message is trivially short (e.g. "ok", "繼續", "謝謝", "thanks"), a pure clarification question, or the user is answering a pending Cluolingo question.
TXT

# --- quiz + background-dispatch instruction (only when a quiz is due) ---
read -r -d '' GATE <<'TXT' || true

CLUOLINGO MODE IS ACTIVE for this turn. If — and only if — this message is a SUBSTANTIVE task (real work: code changes, research, multi-step), do ALL of the following:
1. Dispatch the actual task to a BACKGROUND agent (Agent tool, or Bash run_in_background for long commands) so the real work proceeds while you talk. Mention in one line what you kicked off.
2. Then, casually — as a genuine "by the way" aside — slip in ONE short __TARGET__ question framed like "btw, while that runs, quick one:". Use a single fill-in-the-blank or multiple-choice item drawn from the __TARGET__ rewrite or the phrasing notes. Keep it light and conversational, not a formal quiz block. Do NOT reveal the answer. Then register it out-of-band by running via Bash: `cluo ask "<correct answer>" "<one-line explanation>"`. Tell the user they can answer with `! btw answer <their answer>` (zero-token, does not interrupt the main flow) or just reply in chat.
3. NEVER block on it. The moment the background task reports back, surface its result regardless of whether the user answered. The aside is optional practice, never a gate.
4. The user may answer either way: (a) via `! btw answer <ans>` (or `! cluo answer <ans>`) — the CLI scores it out-of-band, so you do not need to do anything; or (b) by replying in chat — then grade it warmly in one line and record it via Bash: `cluo grade correct` or `cluo grade wrong`, plus `cluo word <theword>` for each new vocab item taught. Either way, if the `cluo` command is not found, skip silently.
For a trivial or quick message, just drop the "btw" aside inline (or skip entirely if trivially short) and do not spawn a background agent.
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
