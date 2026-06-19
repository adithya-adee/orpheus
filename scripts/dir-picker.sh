#!/usr/bin/env bash
# Orpheus · choose the music directory from the TUI (bound to M).
# Opens an fzf list of folders under your music roots; Enter switches MPD to it
# (or pick "Reset"). Also runnable from a shell.
set -uo pipefail

DIR="/home/glitchy_moon/github_repo/orpheus"
SET="$DIR/scripts/set-music-dir.sh"

# Triggered from a keybind (no terminal)? Open one.
if [ ! -t 0 ]; then
  for term in "${TERMINAL:-}" kitty gnome-terminal alacritty wezterm xterm; do
    [ -n "$term" ] && command -v "$term" >/dev/null 2>&1 || continue
    case "$term" in
      gnome-terminal) exec env ORPHEUS_POPUP=1 "$term" --title "Orpheus · Music folder" -- "$0" ;;
      *)              exec env ORPHEUS_POPUP=1 "$term" -e "$0" ;;
    esac
  done
  exit 0
fi

reset_label="↺  Reset to ~/Music/Music"
list="$(mktemp)"
{
  printf '%s\n' "$reset_label"
  for r in "$HOME/Music" "$HOME/music" "$HOME/Downloads" "$HOME/Media"; do
    [ -d "$r" ] && find -L "$r" -maxdepth 3 -type d 2>/dev/null
  done | sort -u
} > "$list"

sel="$(fzf --prompt='music folder ❯ ' --layout=reverse --height=100% --cycle \
  --header='↑/↓ or j/k · Enter select · Esc cancel · (current: '"$("$SET" 2>/dev/null | sed 's/.*: //')"')' \
  --bind='j:down,k:up' < "$list")" || sel=""
rm -f "$list"

[ -z "$sel" ] && { [ -n "${ORPHEUS_POPUP:-}" ] && exit 0; exit 0; }
case "$sel" in
  "$reset_label") "$SET" --reset ;;
  *)              "$SET" "$sel" ;;
esac

[ -n "${ORPHEUS_POPUP:-}" ] && { echo; read -rp "Press Enter to close…" _; }
