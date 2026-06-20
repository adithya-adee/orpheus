#!/usr/bin/env bash
# Orpheus · toggle ❤ favorite on the current song (stored as an MPD sticker).
DIR="/home/glitchy_moon/github_repo/orpheus"
C="$DIR/config.ron"

uri="$(rmpc -c "$C" song 2>/dev/null | jq -r '.file // empty')"
[ -z "$uri" ] && { rmpc remote status "No song playing" >/dev/null 2>&1; exit 0; }

if [ "$(rmpc -c "$C" sticker get "$uri" orpheus_love 2>/dev/null | jq -r '.value // empty')" = "1" ]; then
  rmpc -c "$C" sticker delete "$uri" orpheus_love >/dev/null 2>&1
  rmpc remote status "♡  Removed from favorites" >/dev/null 2>&1
else
  rmpc -c "$C" sticker set "$uri" orpheus_love 1 >/dev/null 2>&1
  rmpc remote status "❤  Added to favorites" >/dev/null 2>&1
fi
