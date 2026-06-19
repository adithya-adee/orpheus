#!/usr/bin/env bash
# Orpheus · base16 → theme converter.
# Reuses theme.ron as the layout template and swaps in a base16 palette, so any
# of the ~250 base16 schemes (the same family termusic ships) becomes an
# Orpheus theme without rewriting the layout.
#   base16-to-orpheus.sh <scheme.yaml> [output-name]
set -euo pipefail

src="${1:?usage: base16-to-orpheus.sh <scheme.yaml> [name]}"
DIR="/home/glitchy_moon/github_repo/orpheus"
name="${2:-$(basename "$src" | sed 's/\.[^.]*$//' | tr ' ' '-')}"
mkdir -p "$DIR/themes"

# Pull the first 6-hex value off a `baseNN:` line (handles "#abc123"/"abc123").
get() { grep -iE "^[[:space:]]*$1:" "$src" | head -1 | grep -oiE '[0-9a-f]{6}' | head -1; }
for n in 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F; do
  v="$(get "base$n")" || true
  if [ -z "${v:-}" ]; then echo "error: base$n missing in $src" >&2; exit 1; fi
  printf -v "B$n" '#%s' "$(printf '%s' "$v" | tr 'A-F' 'a-f')"
done

# Map the theme.ron Frost/Nord palette → the incoming base16 slots.
# Spread the accents across distinct hues so themes don't all look blue:
#   borders = base0D (blue, subtle) · selection/active = base0A (yellow, warm
#   contrast) · artist/secondary = base0E (magenta). The remaining structural
#   slots (bg/text/dim) and status colors (red/green) map straight through.
sed \
  -e "s/#2e3440/${B00}/g" \
  -e "s/#3b4252/${B01}/g" \
  -e "s/#4c566a/${B03}/g" \
  -e "s/#e5e9f0/${B05}/g" \
  -e "s/#eceff4/${B06}/g" \
  -e "s/#81a1c1/${B0D}/g" \
  -e "s/#8fbcbb/${B0E}/g" \
  -e "s/#88c0d0/${B0A}/g" \
  -e "s/#bf616a/${B08}/g" \
  -e "s/#ebcb8b/${B09}/g" \
  -e "s/#a3be8c/${B0B}/g" \
  -e "s/#b48ead/${B0E}/g" \
  "$DIR/theme.ron" > "$DIR/themes/${name}.ron"

echo "wrote themes/${name}.ron"
