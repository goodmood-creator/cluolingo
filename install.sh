#!/usr/bin/env bash
# cluolingo :: global installer (non-plugin path)
# Wires the UserPromptSubmit hook into ~/.claude/settings.json and puts `cluo` on PATH.
# Idempotent: safe to re-run. To uninstall: ./install.sh --uninstall
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CONFIG_DIR/settings.json"
HOOK="$REPO_DIR/hooks/cluolingo.sh"
CLI="$REPO_DIR/scripts/cluo"
BIN_DIR="$HOME/.local/bin"

command -v jq >/dev/null 2>&1 || { echo "❌ jq is required (brew install jq)"; exit 1; }
chmod +x "$HOOK" "$CLI"
mkdir -p "$CONFIG_DIR" "$BIN_DIR"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

_save_settings() { # _save_settings [jq-args...] '<filter>'
  local tmp; tmp="$(mktemp)"
  jq "$@" "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
}

if [ "${1:-}" = "--uninstall" ]; then
  _save_settings '
    if .hooks.UserPromptSubmit then
      .hooks.UserPromptSubmit |= ( map( .hooks |= map(select(.command | test("/cluolingo.sh") | not)) )
                                   | map(select(.hooks | length > 0)) )
    else . end'
  rm -f "$BIN_DIR/cluo" "$BIN_DIR/btw"   # btw included to clean up legacy installs
  rm -f "$CONFIG_DIR/commands/btw.md"
  echo "✅ cluolingo uninstalled (hook + cluo symlink + /btw command removed). State in $CONFIG_DIR/cluolingo kept."
  exit 0
fi

# --- link the CLI onto PATH ---
ln -sf "$CLI" "$BIN_DIR/cluo"
echo "🔗 linked cluo -> $BIN_DIR/"

# --- install the /btw slash command (user-level), wired to this CLI ---
# Plugin installs get commands/btw.md via the plugin system (it uses
# $CLAUDE_PLUGIN_ROOT). The manual path has no plugin root, so we generate a
# user-level command that points straight at the absolute CLI path here.
mkdir -p "$CONFIG_DIR/commands"
cat > "$CONFIG_DIR/commands/btw.md" <<EOF
---
description: Answer the latest Cluolingo language question — scored instantly, out of band
argument-hint: <your answer>
allowed-tools: Bash
---
You are scoring the user's answer to the most recent pending **Cluolingo** quiz question.

Their answer: **\$ARGUMENTS**

Result from the scorer:

!\`"$CLI" answer "\$ARGUMENTS"\`

Relay that result to the user in one short, warm line — it already shows whether they were correct, the right answer, and a one-line explanation. Do **not** start any task, spawn a background agent, or pose a new question. This turn only scores their answer.
EOF
echo "🔗 installed /btw command -> $CONFIG_DIR/commands/btw.md"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "⚠️  $BIN_DIR is not on your PATH. Add to your shell rc:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

# --- wire the UserPromptSubmit hook idempotently ---
_save_settings --arg cmd "$HOOK" '
  .hooks //= {} |
  .hooks.UserPromptSubmit //= [] |
  # drop any prior cluolingo entries
  .hooks.UserPromptSubmit |= ( map( .hooks |= map(select(.command | test("/cluolingo.sh") | not)) )
                               | map(select(.hooks | length > 0)) ) |
  # append ours
  .hooks.UserPromptSubmit += [ { "hooks": [ { "type": "command", "command": $cmd } ] } ]'

echo "✅ cluolingo installed."
echo "   hook     : $HOOK"
echo "   settings : $SETTINGS"
echo "   command  : /btw <answer>  (also available; restart Claude Code to load it)"
echo "   try      : cluo stats   ·   cluo lang Japanese   (or restart Claude Code and start a task)"
