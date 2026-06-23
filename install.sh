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
  rm -f "$CONFIG_DIR/commands/btw.md"    # clean up legacy /btw command (collided with built-in)
  echo "✅ cluolingo uninstalled (hook + cluo symlink removed). State in $CONFIG_DIR/cluolingo kept."
  exit 0
fi

# --- link the CLI onto PATH ---
ln -sf "$CLI" "$BIN_DIR/cluo"
echo "🔗 linked cluo -> $BIN_DIR/"

# --- clean up the legacy /btw command from earlier buggy versions ---
# `/btw` is a BUILT-IN Claude Code command; a previous version shadowed it with a
# user-level command. Remove it so the built-in works. Answer quizzes with
# `cluo answer <ans>` (or reply in chat / use the built-in `/btw`).
rm -f "$CONFIG_DIR/commands/btw.md"
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
echo "   try      : cluo stats   ·   cluo lang Japanese   (or restart Claude Code and start a task)"
