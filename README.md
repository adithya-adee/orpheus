# Orpheus

A themed terminal music player — [rmpc](https://github.com/mierak/rmpc) (MPD client)
dressed up with a blue/white *Frost* theme, vim + ncmpcpp keybindings, one-key
YouTube downloads, and synced scrolling lyrics. Named for the Greek musician
whose song moved gods, beasts, and stones.

> Orpheus is **not a fork** — it's a curated rmpc config + helper scripts + a
> launcher. rmpc does the heavy lifting; this repo is the experience on top.

## Requirements

- `rmpc`, `mpd` (running), `yt-dlp`, `ffmpeg`, `xclip`, `curl`, `jq`
- A running MPD instance pointed at your music (`~/.config/mpd/mpd.conf`)

## Install

```bash
ln -sf ~/github_repo/orpheus/bin/orpheus        ~/.local/bin/orpheus
ln -sf ~/github_repo/orpheus/scripts/orpheus-yt ~/.local/bin/orpheus-yt
orpheus
```

## Keybindings (vim + ncmpcpp)

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `j`/`k` `h`/`l` | move / pane | `1`–`7` | switch tab |
| `gg` / `G` | top / bottom | `/` `n` `N` | search / next / prev |
| `<CR>` | play | `<Space>` | add / select |
| `p` | pause | `>` / `<` | next / prev track |
| `+`/`-` `.`/`,` | volume | `f` / `b` | seek |
| `z` `x` `c` `v` | repeat / random / consume / single | `u` | update library |
| **`y`** | **YouTube add (clipboard URL or query)** | `?` | help |

## YouTube

- **`y`** in-app: copy a link (or a song name) → press `y` → it downloads as
  SponsorBlock-cleaned mp3 into `~/Music/Music` and refreshes the library.
- CLI: `orpheus-yt "song name artist"`.
- No browser is involved, so there is **no ad/malvertising surface**; sponsor
  segments are stripped with `--sponsorblock-remove`.

## Lyrics

`scripts/lrc-fetch.sh` runs on every song change (rmpc `on_song_change`), pulls
synced `.lrc` from [LRCLIB](https://lrclib.net) into `~/.lyrics`, and rmpc
scrolls them in time in the Lyrics pane.

## Themes

The *Frost* (blue/white) theme is `theme.ron`. The whole base16 family (what
termusic ships) can be generated into `themes/`:

```bash
scripts/fetch-themes.sh                          # build the curated catalog
scripts/base16-to-orpheus.sh scheme.yaml mytheme # convert any base16 scheme
ORPHEUS_THEME=dracula orpheus                    # launch with an alternate
```

## Layout

```
config.ron   rmpc config: layout, tabs, keybinds, lyrics + youtube hooks
theme.ron    Frost blue/white theme (layout template for the converter)
themes/      generated base16 themes
scripts/     yt-add.sh · orpheus-yt · lrc-fetch.sh · base16-to-orpheus.sh · fetch-themes.sh
bin/orpheus  launcher (rmpc -c config.ron -t <theme>)
```
