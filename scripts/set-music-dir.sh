#!/usr/bin/env bash
# Orpheus · point the library at a different music folder (instead of the one
# big ~/Music/Music). Rewrites MPD's music_directory, restarts MPD, re-indexes.
#   orpheus-dir /path/to/folder    # use a custom directory
#   orpheus-dir --reset            # back to ~/Music/Music
#   orpheus-dir                    # show the current directory
set -euo pipefail

conf="$HOME/.config/mpd/mpd.conf"
[ -f "$conf" ] || { echo "MPD config not found: $conf"; exit 1; }

current() { awk -F'"' '/^[[:space:]]*music_directory/{print $2}' "$conf"; }

case "${1:-}" in
  -h|--help) echo "usage: orpheus-dir <path> | --reset | (no arg = show current)"; exit 0 ;;
  "")        echo "current music_directory: $(current)"; exit 0 ;;
  --reset)   new="$HOME/Music/Music" ;;
  *)         new="$(readlink -f -- "$1")" ;;
esac

[ -d "$new" ] || { echo "Not a directory: $new"; exit 1; }

cp -f "$conf" "$conf.bak"          # safety backup
if grep -qE '^[[:space:]]*music_directory' "$conf"; then
  sed -i -E "s|^[[:space:]]*music_directory.*|music_directory    \"$new\"|" "$conf"
else
  printf 'music_directory    "%s"\n' "$new" >> "$conf"
fi
echo "music_directory → $new   (backup: $conf.bak)"

if systemctl --user restart mpd 2>/dev/null; then
  echo "restarted MPD"
else
  echo "could not restart the MPD user service — run:  systemctl --user restart mpd"
fi
sleep 1
rmpc update >/dev/null 2>&1 || true
echo "re-indexing… press  u  in Orpheus to refresh the view."
