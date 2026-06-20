#!/usr/bin/env bash
# Orpheus · synced-lyrics fetcher (run by rmpc via on_song_change).
# Pulls .lrc lyrics for the current track from LRCLIB into ~/.lyrics so rmpc's
# lyrics pane can scroll them in time. Best-effort and silent on a miss.
set -uo pipefail

LYR="$HOME/.lyrics"
mkdir -p "$LYR"

title="${TITLE:-}"; artist="${ARTIST:-}"; album="${ALBUM:-}"; dur="${DURATION:-}"
[ -z "$title" ] && exit 0

slug="$(printf '%s - %s' "${artist:-Unknown}" "$title" | tr '/:' '__')"
out="$LYR/$slug.lrc"
[ -s "$out" ] && { echo cached; exit 0; }   # already cached

durarg=()
[[ "$dur" =~ ^[0-9]+$ ]] && durarg=(--data-urlencode "duration=$dur")

resp="$(curl -fsG 'https://lrclib.net/api/get' \
  --data-urlencode "artist_name=$artist" \
  --data-urlencode "track_name=$title" \
  --data-urlencode "album_name=$album" \
  "${durarg[@]}" 2>/dev/null)" || resp=""

synced="$(printf '%s' "$resp" | jq -r '.syncedLyrics // empty' 2>/dev/null)" || synced=""
plain="$( printf '%s' "$resp" | jq -r '.plainLyrics  // empty' 2>/dev/null)" || plain=""

# Fall back to the search endpoint, preferring synced, then plain.
if [ -z "$synced" ] && [ -z "$plain" ]; then
  sresp="$(curl -fsG 'https://lrclib.net/api/search' \
    --data-urlencode "artist_name=$artist" \
    --data-urlencode "track_name=$title" 2>/dev/null)" || sresp=""
  synced="$(printf '%s' "$sresp" | jq -r '[.[] | select(.syncedLyrics != null)][0].syncedLyrics // empty' 2>/dev/null)" || synced=""
  [ -z "$synced" ] && plain="$(printf '%s' "$sresp" | jq -r '[.[] | select(.plainLyrics != null)][0].plainLyrics // empty' 2>/dev/null)" || true
fi

# Prefer timed lyrics; otherwise save plain (displayed without scrolling).
body="${synced:-$plain}"
[ -z "$body" ] && exit 0

{
  printf '[ar:%s]\n[ti:%s]\n' "$artist" "$title"
  [ -n "$album" ] && printf '[al:%s]\n' "$album"
  printf '%s\n' "$body"
} > "$out"
echo fetched
