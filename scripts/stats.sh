#!/usr/bin/env bash
# Orpheus · listening stats from play-count stickers. Bound to gs (popup) or
# run from a shell.
set -uo pipefail
DIR="/home/glitchy_moon/github_repo/orpheus"
C="$DIR/config.ron"

if [ ! -t 0 ]; then
  for term in "${TERMINAL:-}" kitty gnome-terminal alacritty xterm; do
    [ -n "$term" ] && command -v "$term" >/dev/null 2>&1 || continue
    case "$term" in
      gnome-terminal) exec env ORPHEUS_POPUP=1 "$term" --title "Orpheus · Stats" -- "$0" ;;
      *)              exec env ORPHEUS_POPUP=1 "$term" -e "$0" ;;
    esac
  done
  exit 0
fi

echo "  ♪  Orpheus — most played"
echo
rmpc -c "$C" sticker find "" orpheus_playcount 2>/dev/null \
  | jq -r 'sort_by(.value|tonumber)|reverse|.[0:25][]|"\(.value)\t\(.file)"' \
  | awk -F'\t' '{printf "   %4d   %s\n", $1, $2}'
total="$(rmpc -c "$C" sticker find "" orpheus_playcount 2>/dev/null | jq '[.[].value|tonumber]|add // 0')"
favs="$( rmpc -c "$C" sticker find "" orpheus_love       2>/dev/null | jq 'length // 0')"
echo
echo "   total plays: ${total:-0}    ·    favorites: ${favs:-0}"
[ -n "${ORPHEUS_POPUP:-}" ] && { echo; read -rp "Press Enter to close…" _; }
