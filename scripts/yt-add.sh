#!/usr/bin/env bash
# Orpheus · YouTube add (bound to `y`).
# Reads the clipboard: a URL is downloaded directly; anything else is treated
# as a search query. Audio is extracted to mp3, SponsorBlock-stripped, and
# dropped into the music library, then MPD is refreshed. No browser involved,
# so there is zero ad/malvertising surface.
set -uo pipefail

MUSIC_DIR="$HOME/Music/Music"
LOG="$HOME/.cache/orpheus-yt.log"
mkdir -p "$MUSIC_DIR" "$(dirname "$LOG")"

note() {
  command -v notify-send >/dev/null 2>&1 && notify-send "Orpheus ⤓ YouTube" "$1"
  printf '%s %s\n' "$(date '+%F %T')" "$1" >> "$LOG"
}

clip="$(xclip -selection clipboard -o 2>/dev/null | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
if [ -z "$clip" ]; then
  note "Clipboard empty — copy a YouTube link (or a song name), then press y."
  exit 0
fi

# Sponsor segments to remove from the saved audio (the "Brave-like" skip).
SB="sponsor,selfpromo,interaction"
common=(--no-playlist -x --audio-format mp3 --audio-quality 0 --embed-metadata
        --sponsorblock-remove "$SB" -o "$MUSIC_DIR/%(title)s.%(ext)s")

case "$clip" in
  http*://*) note "Downloading link…"; tgt="$clip" ;;
  *)         note "Searching: $clip";  tgt="ytsearch1:$clip" ;;
esac

if yt-dlp "${common[@]}" "$tgt" >> "$LOG" 2>&1; then
  rmpc update >/dev/null 2>&1 || true
  note "Added to library ✓"
else
  note "Failed — see $LOG"
fi
