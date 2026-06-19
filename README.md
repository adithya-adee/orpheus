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
| **`P`** | **add song → playlist (existing or new)** | `8` `9` `0` | YouTube / Config / Themes tab |
| **`t`** / **`T`** | **next / previous theme (live)** | `6` | Playlists tab |

## YouTube

- **`y`** in-app: copy a link (or a song name) → press `y` → it downloads as
  SponsorBlock-cleaned mp3 into `~/Music/Music` and refreshes the library.
- CLI: `orpheus-yt "song name artist"`.
- No browser is involved, so there is **no ad/malvertising surface**; sponsor
  segments are stripped with `--sponsorblock-remove`.

## Playlists (Spotify-style add-to-playlist)

Highlight any song (in Artists / Albums / Search / Queue) and press **`P`** — a
modal opens to pick an existing playlist **or type a new name to create one**,
and the song is added there. Browse and load playlists in the **Playlists** tab
(`6`); save the whole current queue as a playlist with `Ctrl-s a`.

## Lyrics

`scripts/lrc-fetch.sh` runs on every song change (rmpc `on_song_change`), pulls
synced `.lrc` from [LRCLIB](https://lrclib.net) into `~/.lyrics`, and rmpc
scrolls them in time in the Lyrics pane.

## Themes

Open the **Themes** tab (`0`) to see the catalog, then press **`t`** / **`T`**
to cycle themes **live** — applied instantly via rmpc IPC, no restart. The
*Frost* blue/white default is `theme.ron`; 12 base16 themes live in `themes/`.

```bash
scripts/theme-switch.sh dracula                  # jump straight to one
scripts/fetch-themes.sh                          # (re)build the base16 catalog
scripts/base16-to-orpheus.sh scheme.yaml mytheme # convert any base16 scheme
ORPHEUS_THEME=dracula orpheus                    # or choose at launch
```

## Layout

```
config.ron   rmpc config: layout, tabs, keybinds, lyrics + youtube hooks
theme.ron    Frost blue/white theme (layout template for the converter)
themes/      generated base16 themes
scripts/     yt-add.sh · orpheus-yt · lrc-fetch.sh · base16-to-orpheus.sh · fetch-themes.sh
bin/orpheus  launcher (rmpc -c config.ron -t <theme>)
```
