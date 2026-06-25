# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Cluolingo is a **Claude Code plugin** (not a standalone app): a non-blocking language-practice companion. Two cooperating Bash parts, **no build step**. The "product" is the text a `UserPromptSubmit` hook injects into Claude on every prompt — telling Claude to rewrite the user's request into their target language and slip in a quiz, while the real task runs in the background.

## Commands

- **Run tests:** `bash tests/smoke.sh` — self-contained smoke test that runs against a throwaway `CLAUDE_CONFIG_DIR` sandbox, so it never touches real state. It also `bash -n` syntax-checks the scripts. There is no test framework and no per-test selection: it's one script, all-or-nothing.
- **Install locally (dev):** `./install.sh` — wires the hook into `~/.claude/settings.json` and symlinks `cluo` into `~/.local/bin`. Idempotent (safe to re-run). Uninstall: `./install.sh --uninstall`.
- **Hard dependency:** `jq` (`brew install jq`). No package manager, build, or linter.

## Architecture

Two parts that never call each other directly — they communicate only through a shared JSON state file.

**1. The hook — `hooks/cluolingo.sh` (`UserPromptSubmit`)**
- On every prompt it prints one JSON object: `{hookSpecificOutput:{hookEventName, additionalContext}}`. The `additionalContext` string *is* the product — it instructs the main agent to emit the **`English version` → `Phrasing notes:` → `Quick quiz:`** format and to dispatch real work to a background agent.
- Two instruction blocks built as heredocs: `BASE` (always injected — the rewrite + phrasing-notes format) and `GATE` (appended only when a quiz is "due"). `should_trigger()` decides due-ness from `mode`: `every` | `freq` (every N prompts) | `chance` (`RANDOM % 100 < chance`).
- **Fail-open is the prime directive.** If `jq` is missing, the companion is disabled, or the prompt starts with `!` (a shell command), the hook exits 0 with **no output** so the prompt always passes. Never add a path that can block a prompt.
- The hook runs no AI and emits no scores; it only produces instruction text.

**2. The CLI — `scripts/cluo` (state + scoreboard)**
- One invocation-name-agnostic Bash script. Subcommands: `stats|state`, `on|off`, `lang`, `native`, `ask`, `answer`, `pending`, `grade`, `word`, `preset`, `set`, `reset`, `help`.
- Called by **Claude** (`ask` to queue a question; `grade`/`word` when grading a chat reply) and by **the user** (`answer`, `stats`, settings). Run inside Claude Code with the zero-token `!` prefix, e.g. `! cluo answer pagination`.
- State: `$CLAUDE_CONFIG_DIR/cluolingo/state.json` (default `~/.claude/cluolingo/`). All writes are atomic (`mktemp` + `mv`).

**State shape** (single JSON file): `enabled, mode, freq, chance, target_lang, native_lang, answer_scope, prompt_count, quiz_count, correct, streak, best_streak, pending, words_seen`.
- `pending` is a **QUEUE** of `{answer, explain, q, session}`, not a single slot — so concurrent sessions/agents each `cluo ask` without clobbering. Each item is tagged with `$CLAUDE_CODE_SESSION_ID` at `ask` time; **`cluo answer` grades the current session's most-recent item** and pops it (falls back to global most-recent when no session id is set; legacy untagged items stay answerable by anyone). This session-scoping is what makes parallel sessions answer their OWN quizzes instead of each other's.
- **Answering a specific / older question:** `cluo answer @N` targets the N-th open question (1-based, the number peek/`pending` print — newest last), instead of the most-recent. The `@` prefix is deliberate: `#` is a shell comment and a bare integer would collide with numeric answers.
- **Batch answering:** `cluo answer @N=ans @M=ans …` grades several in one call. Critical invariant: ALL `@N` are resolved to real `.pending` indices against the *current* numbering **before any are popped**, then removed together by index set — otherwise popping `@1` would renumber `@2` (off-by-one). Bare args after a pair append to its answer, so multi-word answers survive even unquoted.
- **Scope** (`answer_scope`, `session`|`all`, default `session`): which sessions' questions `cluo answer` can reach. `cluo answer --all` widens a single call to **every** session's backlog (to drain orphans left by finished sessions); `--mine`/`--session` narrows a single call back. `cluo set scope all|session` changes the persisted default; the per-call flag always overrides it. `--all` is the only thing that lets one session answer another's questions, so the parallel-isolation invariant holds unless explicitly opted out.

## Non-obvious invariants (don't regress these)

- **`/btw` is a BUILT-IN Claude Code command** (ask a side question mid-task; it runs in a **read-only fork**, so it can give feedback but cannot persist a score). Do **not** ship a custom `/btw` command — it would shadow the built-in. Scoring happens only via `! cluo answer` (shell) or a chat reply (where Claude runs `cluo grade`).
- **`.enabled` is read raw**, never as `.enabled // true` — jq's `//` treats `false` as empty, which would silently re-enable a disabled companion. Preserve that pattern.
- **The quiz is called "Quick quiz"** in all user-facing text; "btw" was retired as our term precisely because it collided with the built-in `/btw`.
- **Editing `hooks/cluolingo.sh` changes live behavior** for every installed session, but hooks load at **session start** — changes only show up in a fresh session.
- **`__TARGET__` / `__NATIVE__`** are placeholders substituted from state before the heredocs are emitted. Section LABELS stay English; only practice content uses the configured languages.
- Inside hook/slash-command contexts `~/.local/bin` may not be on PATH — prefer `${CLAUDE_PLUGIN_ROOT}/scripts/cluo` (plugin installs) or an absolute path when reliability matters.

## Distribution (two install paths)

- **Plugin:** `/plugin marketplace add goodmood-creator/cluolingo` then `/plugin install cluolingo@cluolingo`. The hook is wired via `hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}`. Note: plugin installs do **not** put `cluo` on PATH (only `install.sh` does).
- **Manual:** `./install.sh`. Marketplace metadata lives in `.claude-plugin/marketplace.json`; the plugin manifest in `.claude-plugin/plugin.json`.

## Docs

`README.md` is the source of truth, with **6 translations** (`README.zh-CN`, `README.zh-TW`, `README.ja`, `README.ko`, `README.es`, `README.pt`). All seven share an identical section structure and a language-switcher line. When you change user-facing behavior, update all seven — there is no automated sync.
