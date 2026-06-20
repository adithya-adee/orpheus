#!/usr/bin/env bash
# Orpheus · sleep timer — pause playback after N minutes. Bound to Z (popup
# picker) or:  sleep-timer.sh <minutes|off>
set -uo pipefail
DIR="/home/glitchy_moon/github_repo/orpheus"
C="$DIR/config.ron"
PIDF="$HOME/.cache/orpheus/sleep.pid"
mkdir -p "$HOME/.cache/orpheus"

if [ ! -t 0 ] && [ -z "${1:-}" ]; then
  for term in "${TERMINAL:-}" kitty gnome-terminal alacritty xterm; do
    [ -n "$term" ] && command -v "$term" >/dev/null 2>&1 || continue
    case "$term" in
      gnome-terminal) exec env ORPHEUS_POPUP=1 "$term" --title "Orpheus · Sleep" -- "$0" ;;
      *)              exec env ORPHEUS_POPUP=1 "$term" -e "$0" ;;
    esac
  done
  exit 0
fi

cancel() { [ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null; rm -f "$PIDF"; }

min="${1:-}"
[ -z "$min" ] && min="$(printf '15\n30\n45\n60\n90\noff\n' | fzf --prompt='pause after (min) ❯ ' --layout=reverse --height=100% --bind='j:down,k:up')"
[ -z "$min" ] && exit 0

cancel
if [ "$min" = off ]; then rmpc remote status "Sleep timer cancelled" >/dev/null 2>&1; exit 0; fi
[[ "$min" =~ ^[0-9]+$ ]] || exit 0

setsid bash -c "sleep $((min * 60)); rmpc -c '$C' pause >/dev/null 2>&1; rmpc remote status 'Paused — sleep timer' >/dev/null 2>&1; rm -f '$PIDF'" >/dev/null 2>&1 &
echo $! > "$PIDF"
rmpc remote status "Sleep timer: pausing in $min min" >/dev/null 2>&1
[ -n "${ORPHEUS_POPUP:-}" ] && { echo "Will pause in $min min."; sleep 1; }
