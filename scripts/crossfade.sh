#!/usr/bin/env bash
# Orpheus · toggle crossfade between tracks (0 <-> 5s). Talks to MPD directly
# over its protocol (bash /dev/tcp), so no extra tools needed. Bound to =.
DIR="/home/glitchy_moon/github_repo/orpheus"
C="$DIR/config.ron"
HOST=127.0.0.1
PORT=6600

cur="$(rmpc -c "$C" status 2>/dev/null | jq -r '.xfade // 0')"
[[ "$cur" =~ ^[0-9]+$ ]] || cur=0
sec="${1:-}"
[ -z "$sec" ] && { [ "$cur" -gt 0 ] && sec=0 || sec=5; }

if exec 3<>"/dev/tcp/$HOST/$PORT"; then
  read -r _ <&3
  printf 'crossfade %s\nclose\n' "$sec" >&3
  exec 3>&-
  rmpc remote status "Crossfade: ${sec}s" >/dev/null 2>&1
else
  rmpc remote status "Crossfade: could not reach MPD" >/dev/null 2>&1
fi
