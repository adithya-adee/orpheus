# Orpheus

A themed terminal music player — [rmpc](https://github.com/mierak/rmpc) (MPD client)
dressed up with 18 switchable themes (solarized-dark default), vim + ncmpcpp keys, one-key
YouTube downloads, and synced scrolling lyrics. Named for the Greek musician
whose song moved gods, beasts, and stones.

> Orpheus is **not a fork** — it's a curated rmpc config + helper scripts + a
> launcher. rmpc does the heavy lifting; this repo is the experience on top.

## Requirements

- `rmpc`, `mpd` (running), `yt-dlp`, `ffmpeg`, `xclip`, `curl`, `jq`
- A running MPD instance pointed at your music (`~/.config/mpd/mpd.conf`)

## Install

```bash
ln -sf ~/github_repo/orpheus/bin/orpheus              ~/.local/bin/orpheus
ln -sf ~/github_repo/orpheus/scripts/orpheus-yt       ~/.local/bin/orpheus-yt
ln -sf ~/github_repo/orpheus/scripts/theme-picker.sh  ~/.local/bin/orpheus-theme
ln -sf ~/github_repo/orpheus/scripts/lyrics-sync.sh   ~/.local/bin/orpheus-lyrics
ln -sf ~/github_repo/orpheus/scripts/set-music-dir.sh ~/.local/bin/orpheus-dir
orpheus --version    # Orpheus 1.0.0
orpheus
```

## Keybindings (vim + ncmpcpp)

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `j`/`k` `h`/`l` | move / pane | `1`–`9` | switch tab |
| `gg` / `G` | top / bottom | `/` `n` `N` | search / next / prev |
| `<CR>` | play | `<Space>` | add / select |
| `p` | pause | `>` / `<` | next / prev track |
| `+`/`-` `.`/`,` | volume | `f` `b` `←` `→` | seek ±5s |
| `z` `x` `c` `v` | repeat / random / consume / single | `u` | update library |
| **`y`** | **YouTube add (clipboard URL or query)** | `?` | help |
| **`P`** | **add song → playlist (existing or new)** | `8` `9` | YouTube / Config tab |
| **`t`** | **theme picker (j/k, live preview)** | `6` | Playlists tab |

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

## Lyrics (cached)

On every song change `scripts/lrc-fetch.sh` (rmpc `on_song_change`) checks
`~/.lyrics/`: on a **hit** it just renders (no network), on a **miss** it
fetches synced `.lrc` from [LRCLIB](https://lrclib.net) and saves it. rmpc
scrolls them in time in the Lyrics pane. It's a persistent cache keyed by
artist+title.

Pre-warm the whole library so lyrics are instant before you ever press play:

```bash
orpheus-lyrics            # scan the library, fetch all, report succeeded/failed
orpheus-lyrics /some/dir  # or a specific folder
```

## Themes

Press **`t`** to open the theme picker — an fzf list you navigate with ↑/↓ or
**j/k**; each theme previews **live** on the window (rmpc IPC, no restart),
Enter keeps it, Esc reverts. Your choice is **remembered across launches** and
shown in the **Config** tab (`9`). Default is **solarized-dark**.

18 themes ship (Frost blue/white + 17 base16): solarized, gruvbox, dracula,
monokai, nord, everforest, catppuccin, rose-pine, ayu, onedark … Each spreads
the palette across multiple hues (blue borders · warm selection · accent
artist) so they're genuinely distinct — not all blue.

```bash
orpheus-theme                                    # the picker, from a shell
scripts/theme-switch.sh dracula                  # jump straight to one
scripts/base16-to-orpheus.sh scheme.yaml mytheme # convert any base16 scheme
ORPHEUS_THEME=dracula orpheus                    # force one at launch
```

## Music directory

Point Orpheus at a different folder instead of the whole `~/Music/Music`:

```bash
orpheus-dir ~/Music/Focus    # switch (backs up config, restarts MPD, re-indexes)
orpheus-dir --reset          # back to ~/Music/Music
orpheus-dir                  # show the current directory
```

## Layout

```
config.ron   rmpc config: layout, tabs, keybinds, lyrics + youtube hooks
theme.ron    Frost blue/white theme (layout template for the converter)
themes/      generated base16 themes
scripts/     yt-add.sh · orpheus-yt · lrc-fetch.sh · base16-to-orpheus.sh · fetch-themes.sh
bin/orpheus  launcher (rmpc -c config.ron -t <theme>)
```
