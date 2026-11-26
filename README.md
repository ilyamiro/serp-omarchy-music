# Serpantinum music for Omarchy

The [Serpantinum](https://github.com/ilyamiro/serpantinum) music popup as an Omarchy shell plugin:

- a spinning vinyl with the cover art, a blurred cover backdrop and an animated border in the cover's colours
- a wavy seek bar
- synced lyrics
- a spectrum visualizer
- a 10-band equalizer, channel balance, mono, swap and dynamic range, powered by [serpantinum-audio](https://github.com/ilyamiro/serpantinum-audio)

It follows your Omarchy theme and language.

> Work in progress.

## Install

```bash
omarchy plugin add https://github.com/ilyamiro/serp-omarchy-music.git --enable
```

Click the note in the bar, or bind a key to `omarchy-shell ilyamiro.serpantinum-music toggle`. Tab switches between the equalizer, audio and lyrics pages, and Esc closes the popup. To use your own lyrics, open the lyrics page and choose "Select a local file". It opens your system file picker and accepts `.lrc` and `.txt` files.

## serpantinum-audio

The equalizer, the audio settings and the visualizer need `serpantinum-audio`. If it's missing, the popup offers an Install button. You can also run the same script yourself:

```bash
bash ~/.config/omarchy/plugins/ilyamiro.serpantinum-music/serp/scripts/install-audio.sh
```

It downloads the latest prebuilt release from GitHub, verifies its checksum and installs it to `~/.local/bin`. No password is needed.

## Remove

```bash
omarchy plugin remove ilyamiro.serpantinum-music
```

If the popup installed serpantinum-audio for you and you no longer want it:

```bash
serpantinum-audio ctl quit
rm ~/.local/bin/serpantinum-audio
rm -r ~/.local/share/licenses/serpantinum-audio
```

Stopping the daemon moves your apps back to your normal output. The plugin keeps its equalizer state and cover cache under `$XDG_RUNTIME_DIR/serpantinum`, which is cleared when you log out.

## Network use

While the popup is open, it fetches cover art for the playing track when the player doesn't provide it. On the lyrics page it searches lrclib.net and NetEase for lyrics.

## License

AGPL-3.0, like Serpantinum.
