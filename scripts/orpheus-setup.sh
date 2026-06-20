#!/usr/bin/env bash
# Orpheus · one-time setup for the optional power features that need extra
# packages or background daemons. Safe to re-run (idempotent).
#   • Cava visualizer                 (cava)
#   • Media keys / desktop control    (mpdris2  → MPRIS)
#   • Last.fm / ListenBrainz scrobble  (mpdscribble — you add credentials)
#   • Discord Rich Presence            (mpd-discord-rpc via cargo)
#   • ReplayGain + Cava FIFO in mpd.conf
set -uo pipefail

MPDCONF="$HOME/.config/mpd/mpd.conf"
UNITS="$HOME/.config/systemd/user"
mkdir -p "$UNITS"
say() { printf '\n\033[1;36m== %s\033[0m\n' "$1"; }

say "1/5  Packages (needs sudo)"
sudo apt-get update -qq && sudo apt-get install -y cava mpc mpdscribble mpdris2 playerctl \
  || echo "  manual: sudo apt install cava mpc mpdscribble mpdris2 playerctl"

say "2/5  mpd.conf — ReplayGain + Cava FIFO"
[ -f "$MPDCONF" ] && {
  grep -q 'replaygain' "$MPDCONF" || sed -i '/^auto_update/a replaygain         "auto"' "$MPDCONF"
  grep -q 'orpheus_cava' "$MPDCONF" || cat >> "$MPDCONF" <<'EOF'

audio_output {
    type   "fifo"
    name   "orpheus_cava"
    path   "/tmp/mpd.fifo"
    format "44100:16:2"
}
EOF
  systemctl --user restart mpd 2>/dev/null && echo "  mpd restarted"
}

say "3/5  Media keys (MPRIS via mpDris2)"
if command -v mpDris2 >/dev/null 2>&1; then
  cat > "$UNITS/mpdris2.service" <<EOF
[Unit]
Description=mpDris2 (MPRIS bridge for Orpheus/MPD)
After=mpd.service
[Service]
ExecStart=$(command -v mpDris2)
Restart=on-failure
[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now mpdris2 2>/dev/null && echo "  media keys now control Orpheus"
else
  echo "  mpDris2 not installed (see step 1)"
fi

say "4/5  Scrobbling (Last.fm / ListenBrainz)"
SC="$HOME/.mpdscribble/mpdscribble.conf"
if [ ! -f "$SC" ]; then
  mkdir -p "$(dirname "$SC")" "$HOME/.cache/mpdscribble"
  cat > "$SC" <<'EOF'
# Add ONE service, then:  systemctl --user enable --now mpdscribble
host = localhost
port = 6600

[last.fm]
url      = https://post.audioscrobbler.com/
username = YOUR_LASTFM_USERNAME
password = YOUR_LASTFM_PASSWORD
journal  = ~/.cache/mpdscribble/lastfm.journal

# [listenbrainz]
# url      = https://proxy.listenbrainz.org/
# username = YOUR_NAME
# password = YOUR_LISTENBRAINZ_TOKEN
# journal  = ~/.cache/mpdscribble/listenbrainz.journal
EOF
  echo "  wrote template → edit creds: $SC"
else
  echo "  config exists: $SC"
fi
cat > "$UNITS/mpdscribble.service" <<EOF
[Unit]
Description=mpdscribble (Orpheus scrobbler)
After=mpd.service
[Service]
ExecStart=/usr/bin/mpdscribble --no-daemon --conf %h/.mpdscribble/mpdscribble.conf
Restart=on-failure
[Install]
WantedBy=default.target
EOF
echo "  after adding creds:  systemctl --user enable --now mpdscribble"

say "5/5  Discord Rich Presence (optional)"
if command -v cargo >/dev/null 2>&1; then
  command -v mpd-discord-rpc >/dev/null 2>&1 || { echo "  building mpd-discord-rpc…"; cargo install mpd-discord-rpc >/dev/null 2>&1 && echo "  installed" || echo "  cargo build failed"; }
  if command -v mpd-discord-rpc >/dev/null 2>&1; then
    cat > "$UNITS/mpd-discord-rpc.service" <<EOF
[Unit]
Description=mpd-discord-rpc (Orpheus)
After=mpd.service
[Service]
ExecStart=$(command -v mpd-discord-rpc)
Restart=on-failure
[Install]
WantedBy=default.target
EOF
    echo "  with Discord open:  systemctl --user enable --now mpd-discord-rpc"
  fi
else
  echo "  cargo not found — skip"
fi

systemctl --user daemon-reload 2>/dev/null
say "Done — Visualizer: press V · Media keys: live · Scrobble/Discord: add creds + enable above"
