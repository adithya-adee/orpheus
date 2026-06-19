#!/usr/bin/env bash
# Orpheus · runtime theme switcher — applies a theme instantly via rmpc IPC,
# no restart. Cycles through "frost" (the default theme.ron) plus every
# themes/*.ron, or jumps straight to a named theme.
#   theme-switch.sh next | prev | <name>
set -uo pipefail

DIR="/home/glitchy_moon/github_repo/orpheus"
STATE="$HOME/.cache/orpheus-theme"
mkdir -p "$(dirname "$STATE")"

# Ordered list: frost first, then the catalog (sorted).
mapfile -t names < <(printf 'frost\n'; ls "$DIR"/themes/*.ron 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.ron$//' | sort)
n=${#names[@]}
[ "$n" -eq 0 ] && exit 0

path_for() { if [ "$1" = "frost" ]; then echo "$DIR/theme.ron"; else echo "$DIR/themes/$1.ron"; fi; }

cur="$(cat "$STATE" 2>/dev/null || echo frost)"
idx=0
for i in "${!names[@]}"; do [ "${names[$i]}" = "$cur" ] && idx=$i; done

case "${1:-next}" in
  next) idx=$(( (idx + 1) % n )) ;;
  prev) idx=$(( (idx - 1 + n) % n )) ;;
  *)    found=""
        for i in "${!names[@]}"; do [ "${names[$i]}" = "$1" ] && { idx=$i; found=1; }; done
        [ -z "$found" ] && { rmpc remote status "Unknown theme: $1" >/dev/null 2>&1; exit 1; } ;;
esac

sel="${names[$idx]}"
if rmpc remote set theme "$(path_for "$sel")" >/dev/null 2>&1; then
  printf '%s\n' "$sel" > "$STATE"
  rmpc remote status "Theme · $sel  ($((idx + 1))/$n)" >/dev/null 2>&1 || true
else
  rmpc remote status "Theme switch failed — is Orpheus running?" >/dev/null 2>&1 || true
  exit 1
fi
