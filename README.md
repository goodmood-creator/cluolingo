# 🦉 Cluolingo

> **Claude × Duolingo** — practice a language while your AI does the work. A **non-blocking** companion for [Claude Code](https://claude.com/claude-code).

**English** · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Português](README.pt.md)

One deliberate principle: **it never blocks you.**

Cluolingo sends your real task to a **background agent**, then casually slips a language question into the chat — *"quick quiz while that runs…"*. The moment the work finishes, you get the result — answered or not. A soft companion, never a gate.

Multi-language: practice English by default, or `cluo lang Japanese` / `cluo lang Spanish` / anything.

## How it works

A `UserPromptSubmit` hook injects behavioral context on every prompt. For a substantive task, Claude is instructed to:

1. **Rewrite** your request into polished **{target language}** + 2–4 phrasing notes (the "_Language_ version" block).
2. **Dispatch** the actual work to a background agent so it runs while you talk.
3. **Slip in a quick quiz** — one casual fill-in-the-blank or multiple-choice question drawn from the rewrite.
4. **Never wait.** When the background task reports back, the result is surfaced regardless of the question. The aside is optional practice, not a gate.

When you answer, your scoreboard updates via the `cluo` CLI.

```
You ▸ 幫我把這個列表加上分頁
AI  ▸ English version
        Rewrite: "Add pagination to this list for me."
        Phrasing notes: 分頁 → pagination (not "paging")
      Quick quiz: the act of splitting a list into pages is called p_________?
      🔧 Kicked off the pagination work in the background.
      (answer with `! cluo answer pagination` or just reply — code drops in when ready)
```

## Bonus: the rewrite is a free comprehension check

You fire off a quick, half-formed prompt; before doing the work, Cluolingo echoes back a polished rewrite of it in your target language. If your reading is decent, that rewrite instantly shows you **whether the AI actually understood your request** — so you catch a misread early, before it runs off and builds the wrong thing. The rewrite does double duty: language practice **and** a mirror on the AI's comprehension.

## Answering without disrupting your flow

Three ways to answer — all give the verdict + the correct answer; they differ in the *explanation* and whether they *score*:

| How | Explanation | Scores? |
|---|---|---|
| `! cluo answer pagination` | a fixed one-liner saved when the question was posed — local, zero-token, never enters the chat | ✅ |
| reply `pagination` in chat | Claude grades your actual answer live (catches *how* you slipped); costs a little | ✅ |
| built-in `/btw pagination` | live like a chat reply, but runs in a read-only fork | ❌ |

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

You barely need this. When a quick quiz pops up, **just answer in chat** — Claude grades it and records your score, no command at all. Want a zero-token, instantly-scored reply instead? Use the `!` shell prefix:

```
! cluo answer pagination
```

That's the whole everyday loop: one quiz, one answer. Everything else is occasional.

**Everyday**

| Command | Effect |
|---|---|
| `cluo answer <answer>` | Answer the current pending question (scored instantly). No answer = peek what's open |
| `cluo stats` | Scoreboard — language, accuracy, streak, words learned |

**Settings (set once and forget)**

| Command | Effect |
|---|---|
| `cluo lang <language>` | Target practice language (e.g. `cluo lang Japanese`) |
| `cluo native <language>` | Your native language (default Chinese) |
| `cluo on` / `cluo off` | Enable / disable the companion |
| `cluo preset chill\|normal\|hardcore` | `chill` = 20% chance per task; `normal`/`hardcore` = every task |
| `cluo set mode every\|freq\|chance` · `set freq <N>` · `set chance <0-100>` | Fine-tune when quizzes fire |
| `cluo reset` | Reset the scoreboard (keeps settings) |

<details>
<summary><b>Advanced — only if a backlog piles up</b> (you never need these for normal use)</summary>

If lots of questions accumulate (e.g. across parallel sessions you didn't answer as you went), these let you drain them.

| Command | Effect |
|---|---|
| `cluo pending [--all]` | List open questions, each numbered `@N`. `--all` = every session's, tagged by session id |
| `cluo answer @N <answer>` | Answer a **specific** question by its `@N` number — e.g. answer older ones first |
| `cluo answer @N=ans [@M=ans …]` | **Batch:** grade several at once. All `@N` resolve before any are popped; multi-word answers ok |
| `cluo answer --all [@N] [answer]` | Reach **every** session's backlog (drain orphans from finished sessions) |
| `cluo answer --mine [@N] [answer]` | Limit one call to **this** session (overrides `scope=all`) |
| `cluo set scope all\|session` | Default scope for `cluo answer` (default `session`) |
| `cluo pending clear [--all]` | Clear your open questions; `--all` = every session's |

</details>

<sub>Driven by Claude, not you: `cluo ask` / `cluo grade` / `cluo word` (pending is a queue).</sub>

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

- **every** (default) — every substantive task gets a quick quiz.
- **freq** — ask every `N` prompts.
- **chance** — ask with `chance`% probability per prompt (roulette).

## Escape hatch & fail-open

- Prompts starting with `!` (shell commands) are never touched.
- If `jq` is missing, the companion is disabled, or anything errors, the hook **fails open** — your prompt always goes through.

## State

Scoreboard and settings live in `~/.claude/cluolingo/state.json` (or `$CLAUDE_CONFIG_DIR/cluolingo/`).

## License

MIT
