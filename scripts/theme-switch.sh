#!/usr/bin/env bash
# Orpheus · apply a theme at runtime via rmpc IPC.
#   theme-switch.sh [--preview] <name | next | prev>
# With --preview it only applies (used while scrolling the picker). Without it,
# the choice is remembered (state file) AND written into the runtime Config tab
# so it survives restarts and is shown in-app.
set -uo pipefail

DIR="/home/glitchy_moon/github_repo/orpheus"
STATE="$HOME/.cache/orpheus-theme"
RUNTIME="$HOME/.cache/orpheus/config.ron"

preview=0
[ "${1:-}" = "--preview" ] && { preview=1; shift; }
arg="${1:-next}"

mapfile -t names < <(printf 'frost\n'; ls "$DIR"/themes/*.ron 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.ron$//' | sort)
n=${#names[@]}; [ "$n" -eq 0 ] && exit 0
path_for() { if [ "$1" = frost ]; then echo "$DIR/theme.ron"; else echo "$DIR/themes/$1.ron"; fi; }

cur="$(cat "$STATE" 2>/dev/null || echo solarized-dark)"
idx=0
for i in "${!names[@]}"; do [ "${names[$i]}" = "$cur" ] && idx=$i; done

case "$arg" in
  next) idx=$(( (idx + 1) % n )) ;;
  prev) idx=$(( (idx - 1 + n) % n )) ;;
  *)    found=""
        for i in "${!names[@]}"; do [ "${names[$i]}" = "$arg" ] && { idx=$i; found=1; }; done
        [ -z "$found" ] && { rmpc remote status "Unknown theme: $arg" >/dev/null 2>&1; exit 1; } ;;
esac
sel="${names[$idx]}"

rmpc remote set theme "$(path_for "$sel")" >/dev/null 2>&1 \
  || { rmpc remote status "Theme switch failed — is Orpheus running?" >/dev/null 2>&1; exit 1; }
rmpc remote status "Theme · $sel  ($((idx + 1))/$n)" >/dev/null 2>&1 || true

if [ "$preview" -eq 0 ]; then
  printf '%s\n' "$sel" > "$STATE"          # remember for next launch
  # Reflect it in the Config tab (runtime config), validated before swapping in.
  if [ -f "$RUNTIME" ]; then
    tmp="$(mktemp)"
    sed "s|Current theme:  [^\"]*|Current theme:  $sel   ·   press  t  to change|" "$RUNTIME" > "$tmp"
    if rmpc -c "$tmp" config --current >/dev/null 2>&1; then mv "$tmp" "$RUNTIME"; else rm -f "$tmp"; fi
  fi
fi
