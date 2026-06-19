#!/usr/bin/env bash
# Orpheus · build a theme catalog from upstream base16 schemes.
# Downloads a curated set of base16 palettes (the same family termusic ships)
# and converts each into an Orpheus theme via base16-to-orpheus.sh.
set -uo pipefail

DIR="/home/glitchy_moon/github_repo/orpheus"
BASE="https://raw.githubusercontent.com/tinted-theming/schemes/master/base16"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Curated set, leaning blue/white plus a few popular favorites.
THEMES="nord tokyo-night-dark catppuccin-mocha gruvbox-dark-hard dracula \
solarized-dark onedark ayu-dark rose-pine edge-dark google-dark atelier-forest"

ok=0; fail=0
for t in $THEMES; do
  if curl -fsSL "$BASE/$t.yaml" -o "$TMP/$t.yaml" 2>/dev/null; then
    if "$DIR/scripts/base16-to-orpheus.sh" "$TMP/$t.yaml" "$t" >/dev/null 2>&1; then
      ok=$((ok+1)); echo "  ✓ $t"
    else
      fail=$((fail+1)); echo "  ✗ convert: $t"
    fi
  else
    fail=$((fail+1)); echo "  ✗ download: $t"
  fi
done
echo "themes: $ok built, $fail skipped → $DIR/themes/"
