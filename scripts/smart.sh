#!/usr/bin/env bash
# Orpheus · smart queues. Bound to S (opens an fzf menu in a popup) or run
# directly:  smart.sh <favorites|most-played|never-played|random-mix|shuffle-all>
set -uo pipefail
DIR="/home/glitchy_moon/github_repo/orpheus"
C="$DIR/config.ron"
R() { rmpc -c "$C" "$@"; }

# Popup-relaunch for the picker when triggered from a keybind.
if [ ! -t 0 ] && [ -z "${1:-}" ]; then
  for term in "${TERMINAL:-}" kitty gnome-terminal alacritty xterm; do
    [ -n "$term" ] && command -v "$term" >/dev/null 2>&1 || continue
    case "$term" in
      gnome-terminal) exec env ORPHEUS_POPUP=1 "$term" --title "Orpheus · Smart" -- "$0" ;;
      *)              exec env ORPHEUS_POPUP=1 "$term" -e "$0" ;;
    esac
  done
  exit 0
fi

mode="${1:-}"
if [ -z "$mode" ]; then
  mode="$(printf '%s\n' \
      "favorites|❤  Favorites" \
      "most-played|▲  Most played" \
      "never-played|✧  Never played" \
      "random-mix|⤮  Random mix (40)" \
      "shuffle-all|∞  Shuffle everything" \
    | fzf --with-nth=2 --delimiter='|' --prompt='smart queue ❯ ' \
          --layout=reverse --height=100% --bind='j:down,k:up' | cut -d'|' -f1)"
fi
[ -z "$mode" ] && exit 0

fill() { R clear >/dev/null 2>&1; while IFS= read -r u; do [ -n "$u" ] && R add "$u" >/dev/null 2>&1; done; R play >/dev/null 2>&1; }

case "$mode" in
  favorites)    R sticker find "" orpheus_love 2>/dev/null | jq -r '.[].file' | fill ;;
  most-played)  R sticker find "" orpheus_playcount 2>/dev/null | jq -r 'sort_by(.value|tonumber)|reverse|.[0:50][].file' | fill ;;
  never-played) comm -23 <(R listall 2>/dev/null | sort -u) \
                         <(R sticker find "" orpheus_playcount 2>/dev/null | jq -r '.[].file' | sort -u) \
                  | shuf | head -50 | fill ;;
  random-mix)   R listall 2>/dev/null | shuf | head -40 | fill ;;
  shuffle-all)  R clear >/dev/null 2>&1; R add "/" >/dev/null 2>&1; R random on >/dev/null 2>&1; R play >/dev/null 2>&1 ;;
  *)            exit 0 ;;
esac
rmpc remote status "Smart queue · $mode" >/dev/null 2>&1
[ -n "${ORPHEUS_POPUP:-}" ] && { echo "Queued: $mode"; sleep 1; }
