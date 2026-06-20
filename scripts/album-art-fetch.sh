#!/usr/bin/env bash
# Orpheus · fetch missing album art and embed it into the files (so it shows in
# the Now-Playing pane). Only touches tracks with NO embedded cover. Art comes
# from the Cover Art Archive via MusicBrainz. Bound to gA (popup) or:
#   orpheus-art [music_dir]
set -uo pipefail

DIR="/home/glitchy_moon/github_repo/orpheus"
UA="Orpheus/1.1 ( https://github.com/adithya-adee/orpheus )"

# Popup-relaunch when triggered from a keybind (so you see progress + confirm).
if [ ! -t 0 ]; then
  for term in "${TERMINAL:-}" kitty gnome-terminal alacritty xterm; do
    [ -n "$term" ] && command -v "$term" >/dev/null 2>&1 || continue
    case "$term" in
      gnome-terminal) exec env ORPHEUS_POPUP=1 "$term" --title "Orpheus · Album art" -- "$0" "$@" ;;
      *)              exec env ORPHEUS_POPUP=1 "$term" -e "$0" "$@" ;;
    esac
  done
  exit 0
fi

music="${1:-}"
[ -z "$music" ] && { music="$(awk -F'"' '/^[[:space:]]*music_directory/{print $2}' "$HOME/.config/mpd/mpd.conf" 2>/dev/null)"; music="${music/#\~/$HOME}"; }
music="${music:-$HOME/Music/Music}"
[ -d "$music" ] || { echo "Not a directory: $music"; exit 1; }

has_art() { [ -n "$(ffprobe -v error -select_streams v -show_entries stream=index -of csv=p=0 "$1" 2>/dev/null)" ]; }
tag() { ffprobe -v error -show_entries "format_tags=$1" -of default=nw=1:nk=1 "$2" 2>/dev/null | head -1; }

embed() { # <file> <cover.jpg>
  local f="$1" cover="$2" ext tmp
  ext="${f##*.}"; ext="${ext,,}"; tmp="${f%.*}.__orpheusart__.$ext"
  case "$ext" in
    mp3)         ffmpeg -y -loglevel error -i "$f" -i "$cover" -map 0:a -map 1:v -c copy -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" -disposition:v attached_pic "$tmp" 2>/dev/null ;;
    flac)        ffmpeg -y -loglevel error -i "$f" -i "$cover" -map 0:a -map 1:v -c copy -disposition:v attached_pic "$tmp" 2>/dev/null ;;
    m4a|mp4|aac) ffmpeg -y -loglevel error -i "$f" -i "$cover" -map 0 -map 1 -c copy -disposition:v attached_pic "$tmp" 2>/dev/null ;;
    *) return 1 ;;
  esac
  if [ $? -eq 0 ] && [ -s "$tmp" ]; then mv -f "$tmp" "$f"; return 0; fi
  rm -f "$tmp"; return 1
}

echo "Scanning $music for tracks missing cover art…"
mapfile -t files < <(find -L "$music" -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.flac' \) | sort)
missing=(); for f in "${files[@]}"; do has_art "$f" || missing+=("$f"); done
echo "Found ${#files[@]} tracks, ${#missing[@]} missing art."
[ "${#missing[@]}" -eq 0 ] && { echo "Nothing to do."; [ -n "${ORPHEUS_POPUP:-}" ] && { echo; read -rp "Press Enter…" _; }; exit 0; }

printf 'Embed fetched art into %d files? This modifies the files. [y/N] ' "${#missing[@]}"
read -r ans; case "$ans" in [yY]*) ;; *) echo "Cancelled."; [ -n "${ORPHEUS_POPUP:-}" ] && { read -rp "Press Enter…" _; }; exit 0 ;; esac

tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' EXIT
ok=0; fail=0; i=0
for f in "${missing[@]}"; do
  i=$((i+1))
  artist="$(tag artist "$f")"; album="$(tag album "$f")"
  printf '\r\033[K[%d/%d]  ✓%d ✗%d   %.45s' "$i" "${#missing[@]}" "$ok" "$fail" "${artist:+$artist - }${album:-?}"
  [ -z "$album" ] && { fail=$((fail+1)); continue; }
  mbid="$(curl -fsG -A "$UA" 'https://musicbrainz.org/ws/2/release/' \
    --data-urlencode "query=artist:\"$artist\" AND release:\"$album\"" \
    --data-urlencode 'fmt=json' --data-urlencode 'limit=1' 2>/dev/null | jq -r '.releases[0].id // empty')"
  sleep 1   # MusicBrainz asks for <=1 request/second
  [ -z "$mbid" ] && { fail=$((fail+1)); continue; }
  cover="$tmpd/c.jpg"
  if curl -fsL -A "$UA" "https://coverartarchive.org/release/$mbid/front-500" -o "$cover" 2>/dev/null && [ -s "$cover" ] && embed "$f" "$cover"; then
    ok=$((ok+1))
  else
    fail=$((fail+1))
  fi
done
echo; echo
echo "Done — ${#missing[@]} candidates:  ✓ $ok embedded,  ✗ $fail not found."
echo "Refresh in Orpheus with  u  (or it auto-updates)."
[ -n "${ORPHEUS_POPUP:-}" ] && { echo; read -rp "Press Enter to close…" _; }
