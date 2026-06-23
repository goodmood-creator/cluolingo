---
description: Answer the latest Cluolingo language question — scored instantly, out of band
argument-hint: <your answer>
allowed-tools: Bash
---
You are scoring the user's answer to the most recent pending **Cluolingo** quiz question.

Their answer: **$ARGUMENTS**

Result from the scorer:

!`CLUO="${CLAUDE_PLUGIN_ROOT:-.}/scripts/cluo"; if [ -x "$CLUO" ]; then "$CLUO" answer "$ARGUMENTS"; else cluo answer "$ARGUMENTS"; fi`

Relay that result to the user in one short, warm line — it already shows whether they were correct, the right answer, and a one-line explanation. Do **not** start any task, spawn a background agent, or pose a new question. This turn only scores their answer.
