#!/usr/bin/env bash
# Orpheus · "radio" — append N random tracks to the queue so the music never
# stops. Run from the Smart menu (Shuffle everything) or:  radio.sh [count]
DIR="/home/glitchy_moon/github_repo/orpheus"
C="$DIR/config.ron"
n="${1:-25}"

rmpc -c "$C" listall 2>/dev/null | shuf | head -n "$n" | while IFS= read -r u; do
  [ -n "$u" ] && rmpc -c "$C" add "$u" >/dev/null 2>&1
done
rmpc remote status "Radio: queued $n more tracks" >/dev/null 2>&1
