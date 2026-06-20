#!/usr/bin/env bash
# Orpheus · runs on every song change (rmpc on_song_change). Three jobs, all
# backgrounded so playback never stalls:
#   1. cache synced lyrics (LRCLIB)         2. bump the play-count sticker
#   3. desktop notification with album art
DIR="/home/glitchy_moon/github_repo/orpheus"
C="$DIR/config.ron"

# 1) Lyrics (existing fetcher inherits ARTIST/TITLE/ALBUM/DURATION from rmpc)
"$DIR/scripts/lrc-fetch.sh" >/dev/null 2>&1 &

# 2) Play count (+1) keyed on the song's relative uri
uri="${FILE:-}"
if [ -n "$uri" ]; then
  (
    cur="$(rmpc -c "$C" sticker get "$uri" orpheus_playcount 2>/dev/null | jq -r '.value // 0' 2>/dev/null)"
    [[ "$cur" =~ ^[0-9]+$ ]] || cur=0
    rmpc -c "$C" sticker set "$uri" orpheus_playcount "$((cur + 1))" >/dev/null 2>&1
  ) &
fi

# 3) Now-playing notification with cover art
if command -v notify-send >/dev/null 2>&1; then
  (
    mkdir -p "$HOME/.cache/orpheus"
    art="$HOME/.cache/orpheus/art.jpg"
    rmpc -c "$C" albumart -o "$art" >/dev/null 2>&1 || art="audio-x-generic"
    notify-send -a Orpheus -i "$art" "${TITLE:-Now playing}" "${ARTIST:-Unknown} — ${ALBUM:-}"
  ) &
fi
