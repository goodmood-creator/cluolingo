# 🦉 Cluolingo

> **Claude × Duolingo** — practice a language while your AI does the work. A **non-blocking** companion for [Claude Code](https://claude.com/claude-code).

**English** · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Português](README.pt.md)

One deliberate principle: **it never blocks you.**

Cluolingo sends your real task to a **background agent**, then casually slips a language question into the chat — *"btw, while that runs, quick one…"*. The moment the work finishes, you get the result — answered or not. A soft companion, never a gate.

Multi-language: practice English by default, or `cluo lang Japanese` / `cluo lang Spanish` / anything.

## How it works

A `UserPromptSubmit` hook injects behavioral context on every prompt. For a substantive task, Claude is instructed to:

1. **Rewrite** your request into polished **{target language}** + 2–4 phrasing notes (the "_Language_ version" block).
2. **Dispatch** the actual work to a background agent so it runs while you talk.
3. **Slip in a "btw"** — one casual fill-in-the-blank or multiple-choice question drawn from the rewrite.
4. **Never wait.** When the background task reports back, the result is surfaced regardless of the question. The aside is optional practice, not a gate.

When you answer, your scoreboard updates via the `cluo` CLI.

```
You ▸ 幫我把這個列表加上分頁
AI  ▸ English version
        Rewrite: "Add pagination to this list for me."
        Notes: 分頁 → pagination (not "paging")…
      🔧 Kicked off the pagination work in the background.
      btw, while that runs — quick one:
        the act of splitting a list into pages is called p_________?
      (answer with `! cluo answer pagination` or just reply — code drops in when ready)
```

## Answering without disrupting your flow

Three ways to answer — pick per moment:

- **`! cluo answer pagination` (zero disruption):** the `!` shell prefix runs locally, costs zero tokens, and never enters the conversation, so it doesn't pollute your main task. The CLI scores it instantly.
- **Just reply `pagination` in chat:** Claude grades it warmly with a one-line explanation. A bit more context, but you learn more.
- **Claude Code's built-in `/btw pagination`:** fires your answer as a side note while the task keeps running — Claude reads it and grades you. (That's Claude Code's own command, not part of Cluolingo.)

`cluo` is the full CLI — run it with the `!` prefix (e.g. `! cluo stats`).

## Install

### As a Claude Code plugin (recommended)

```
/plugin marketplace add goodmood-creator/cluolingo
/plugin install cluolingo@cluolingo
```

### Global (manual) install

```
git clone https://github.com/goodmood-creator/cluolingo.git
cd cluolingo
./install.sh
```

This links the `cluo` CLI onto your PATH and wires the hook into `~/.claude/settings.json`. Re-run any time; uninstall with `./install.sh --uninstall`.

> Requires [`jq`](https://jqlang.github.io/jq/) (`brew install jq`).

## The CLI (`cluo`)

Run with the zero-token `!` shell prefix inside Claude Code, e.g. `! cluo stats`.

| Command | Effect |
|---|---|
| `cluo answer <answer>` | Answer the most recent pending question (scored instantly) |
| `cluo pending` | List open (unanswered) questions |
| `cluo stats` | Show scoreboard (language, accuracy, streak, words learned) |
| `cluo lang <language>` | Set the target practice language (e.g. `cluo lang Japanese`) |
| `cluo native <language>` | Set your native language (default Chinese) |
| `cluo on` / `cluo off` | Enable / disable the companion |
| `cluo preset chill\|normal\|hardcore` | `chill` = 20% chance per task; `normal`/`hardcore` = every task |
| `cluo set mode every\|freq\|chance` | Trigger mode |
| `cluo set freq <N>` | In `freq` mode, ask every N prompts |
| `cluo set chance <0-100>` | In `chance` mode, % probability per prompt |
| `cluo reset` | Reset the scoreboard (keeps settings) |
| `cluo ask <answer> [explanation] [question]` · `cluo grade correct\|wrong` · `cluo word <text>` | Called by Claude when posing/grading a question (pending is a queue) |

## Languages

Practice any language — the target is just a label fed to Claude:

```
cluo lang English      # default
cluo lang Japanese
cluo lang Spanish
cluo lang 日本語         # whatever Claude understands
cluo native Chinese    # your native language for the phrasing notes
```

## Trigger modes

- **every** (default) — every substantive task gets a "btw".
- **freq** — ask every `N` prompts.
- **chance** — ask with `chance`% probability per prompt (roulette).

## Escape hatch & fail-open

- Prompts starting with `!` (shell commands) are never touched.
- If `jq` is missing, the companion is disabled, or anything errors, the hook **fails open** — your prompt always goes through.

## State

Scoreboard and settings live in `~/.claude/cluolingo/state.json` (or `$CLAUDE_CONFIG_DIR/cluolingo/`).

## License

MIT
