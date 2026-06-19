#!/usr/bin/env bash
# Orpheus · pre-fetch synced lyrics for the WHOLE library (or a given folder),
# so lyrics are cached before you ever press play. Already-cached tracks are
# skipped instantly. Prints a running tally and a final succeeded/failed report.
#   orpheus-lyrics [music_dir]
set -uo pipefail

DIR="/home/glitchy_moon/github_repo/orpheus"
FETCH="$DIR/scripts/lrc-fetch.sh"

# Resolve the music dir: explicit arg → MPD config → default.
music="${1:-}"
if [ -z "$music" ]; then
  music="$(awk -F'"' '/^[[:space:]]*music_directory/{print $2}' "$HOME/.config/mpd/mpd.conf" 2>/dev/null)"
  music="${music/#\~/$HOME}"
fi
music="${music:-$HOME/Music/Music}"
[ -d "$music" ] || { echo "Not a directory: $music"; exit 1; }

echo "Scanning $music …"
mapfile -t files < <(find -L "$music" -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.flac' -o -iname '*.ogg' -o -iname '*.opus' \) | sort)
total=${#files[@]}
[ "$total" -eq 0 ] && { echo "No audio files found."; exit 0; }
echo "Found $total tracks. Fetching lyrics from LRCLIB (cached tracks skipped)…"
echo

new=0; cached=0; fail=0; i=0
for f in "${files[@]}"; do
  i=$((i + 1))
  artist="$(ffprobe -v error -show_entries format_tags=artist -of default=nw=1:nk=1 "$f" 2>/dev/null | head -1)"
  title="$( ffprobe -v error -show_entries format_tags=title  -of default=nw=1:nk=1 "$f" 2>/dev/null | head -1)"
  album="$( ffprobe -v error -show_entries format_tags=album  -of default=nw=1:nk=1 "$f" 2>/dev/null | head -1)"
  dur="$(   ffprobe -v error -show_entries format=duration    -of default=nw=1:nk=1 "$f" 2>/dev/null | cut -d. -f1)"
  [ -z "$title" ] && title="$(basename "$f" | sed 's/\.[^.]*$//')"

  status="$(ARTIST="$artist" TITLE="$title" ALBUM="$album" DURATION="$dur" bash "$FETCH" 2>/dev/null)"
  case "$status" in
    cached)  cached=$((cached + 1)); mark="·" ;;
    fetched) new=$((new + 1));       mark="✓"; sleep 0.25 ;;   # be gentle on LRCLIB
    *)       fail=$((fail + 1));     mark="✗"; sleep 0.25 ;;
  esac
  printf '\r\033[K[%d/%d]  ✓%d  ·%d cached  ✗%d   %s %.45s' "$i" "$total" "$new" "$cached" "$fail" "$mark" "${artist:+$artist - }$title"
done

echo; echo
echo "Done — $total tracks:"
echo "  ✓ $((new + cached)) have lyrics   ($new newly fetched, $cached already cached)"
echo "  ✗ $fail without synced lyrics on LRCLIB"
echo "Cache: ~/.lyrics/"
