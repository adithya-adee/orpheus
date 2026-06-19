#!/usr/bin/env bash
# Orpheus · interactive theme picker.
# Bound to `t`: opens an fzf list — ↑/↓ or j/k to move (themes preview LIVE on
# the running instance via IPC), Enter keeps the choice, Esc reverts. Also
# runnable straight from a shell: `orpheus-theme`.
set -uo pipefail

DIR="/home/glitchy_moon/github_repo/orpheus"
STATE="$HOME/.cache/orpheus-theme"
SW="$DIR/scripts/theme-switch.sh"

# Launched by the rmpc keybind (no controlling terminal)? Re-open inside one.
if [ ! -t 0 ]; then
  for term in "${TERMINAL:-}" kitty gnome-terminal alacritty wezterm xterm; do
    [ -n "$term" ] && command -v "$term" >/dev/null 2>&1 || continue
    case "$term" in
      gnome-terminal) exec "$term" --title "Orpheus Themes" -- "$0" ;;
      *)              exec "$term" -e "$0" ;;
    esac
  done
  exit 0
fi

orig="$(cat "$STATE" 2>/dev/null || echo frost)"
list() { printf 'frost\n'; ls "$DIR"/themes/*.ron 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.ron$//' | sort; }

# Live preview on highlight needs fzf >= 0.30 (the `focus` event); degrade if older.
ver="$(fzf --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"
focus=()
awk "BEGIN{exit !(${ver:-0} >= 0.30)}" 2>/dev/null && focus=(--bind="focus:execute-silent($SW {} >/dev/null 2>&1)")

sel="$(list | fzf \
  --prompt='theme ❯ ' --layout=reverse --height=100% --cycle \
  --header='↑/↓ or j/k to preview · Enter keep · Esc cancel' \
  --bind='j:down,k:up' "${focus[@]}")" || sel=""

if [ -n "$sel" ]; then
  "$SW" "$sel" >/dev/null 2>&1
else
  "$SW" "$orig" >/dev/null 2>&1   # cancelled → restore
fi
