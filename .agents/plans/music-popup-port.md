# Port the Serpantinum music popup to an Omarchy plugin

- **Status:** In progress (popup ported and running on Omarchy 4.5.0-3 in the VM, 2026-11-26)
- **Commit:** this repo has no commits yet; baselines below
- **Serpantinum baseline:** `714dd983f5843406444fa42245e29363b6f3681b` (`714dd98`)
- **Omarchy baseline:** `omacom/omarchy` branch `quattro` as of 2026-11-26 (latest release `v4.5.0`)
- **Scope:** a single third-party Omarchy shell plugin, `ilyamiro.serpantinum-music`, that ships the Serpantinum music popup with its serpantinum-audio equalizer

## Goal

A user on stock Omarchy 4.5 runs `omarchy plugin add <repo> --enable` and gets a bar button. The button opens the Serpantinum music popup: cover art with a blurred backdrop, track controls with the wavy seek bar, synced lyrics, the spectrum visualizer, and the equalizer page that drives `serpantinum-audio`. The popup keeps Serpantinum's look and takes its colours from the active Omarchy theme. It follows Omarchy's language, motion and safety rules. If `serpantinum-audio` isn't installed, the plugin still works and the equalizer page says what's missing.

## Omarchy plugin contract (verified in Omarchy source)

- `omarchy-shell` is one long-lived Quickshell process. Plugins are QML folders loaded into it from `~/.config/omarchy/plugins/<id>/`. A plugin repo is a git repo with `manifest.json` at its root.
- Manifest: `schemaVersion: 1`, `id`, `name`, `version`, `kinds`, `entryPoints`. There's one entry point per kind: `barWidget`, `panel`, `overlay`, `menu`, `service` or `bar`. Bar widgets need a `barWidget` block. Validation lives in `shell/services/PluginRegistry.qml` (lines 55–90) and is exposed as `omarchy plugin validate <dir>`. Entry paths must be safe relative paths, and **the folder can't contain symlinks**.
- Third-party plugins get capability-scoped facades. A third-party widget **can't obtain first-party services** such as `omarchy.media`, so the plugin needs its own MPRIS state. Quickshell's `Quickshell.Services.Mpris` is usable directly because we're in the same process.
- Third-party QML may import `qs.Commons` (as `Commons` for `Commons.Color`) and `qs.Ui` (`BarWidget`, `WidgetButton`, `PopupCard`, `KeyboardPanel`, …).
- Strings: `Commons.Translations { directory: Qt.resolvedUrl("i18n") }` with flat `i18n/<lang>.json` catalogs and `strings.t()` / `strings.tn()`. Language codes are listed in `$OMARCHY_PATH/default/i18n/locales.json`.
- Motion: every duration goes through `Style.duration(ms)`. Use `Style.easeOut` or `OutCubic`, keep animations under 300 ms, and never scale from 0.
- Safety: never bind untrusted text (track titles, artists, lyrics, command output) to a `Text` in the default `AutoText` format. Use `textFormat: Text.PlainText`. Network fetches must be explicit, bounded and toggleable.
- Saving a file under the plugin folder hot-reloads it. `omarchy agent look plugin <dir>` renders the widget with the current theme and lists QML errors.
- Reference docs in Omarchy: `docs/omarchy-shell.md`, `manual/32-shell-plugins.md`, `default/agents/skills/omarchy-make-plugin/SKILL.md`, `shell/plugins/services/media/BarWidget.qml` (popup pattern), `shell/Ui/PopupCard.qml`.

## Source in Serpantinum (at `714dd98`)

Entry: `src/quickshell/media/MusicPopup.qml` (496 lines). It's hosted by the popout manager at 625×565 (`src/quickshell/WindowRegistry.js:107`). The `media/` folder has 12 QML files (~2,850 lines) plus `equalizer.sh` and `art_fetch.sh`.

The transitive closure computed from type names is 53 files and ~13.6k lines. It includes false positives: `quickactions/actions/Timer.qml` and the `focustimer/` panels match the QtQuick `Timer` type name. The real closure is about 35 files:

- `media/*` (12 QML, 2 scripts)
- `reusables/media/`: `LyricsView`, `Visualizer`, `WavySeekBar`
- `reusables/display/`: `GlassFill`, `GlassLens`, `LiquidGlass`, `MarqueeText`, `WallpaperBlur`
- `reusables/buttons/`: `ClickButton`, `CloseButton`, `IconButton`
- `reusables/inputs/`: `Dropdown`, `Switch`, `Toggle`, `LyricsPicker` (`FilePicker`, `Input`, `TimeSelector` and `guide/SettingsRow` need checking; they may only be used by the lyrics file picker)
- Singletons: `Audio`, `Spectrum`, `MprisController`, `Lyrics`, `Sounds`, `Caching`, `Config`, `I18n`, `Scaler`, `ThemeBackend`, `Matugen`, `Wallpaper`, `AppTheming`

Couplings that have to change:

| Coupling | Where | Problem inside omarchy-shell |
|---|---|---|
| `Caching.qsDir` = `$QS_DIR` env | `singletons/system/Caching.qml:8`, used by `MusicEqualizerState.qml:50,54,129,142,152` and `MprisController.qml:150` | the env var isn't set; scripts must resolve from the plugin folder |
| `equalizer.sh` sources `../../scripts/caching.sh` | `media/equalizer.sh:3` | that path doesn't exist in the plugin |
| `ThemeBackend` reads `~/.local/state/serpantinum/qs_colors.json` | `singletons/theme/ThemeBackend.qml:55-56` | no Serpantinum theme on Omarchy; colours must come from `Commons.Color` |
| `Config` reads `~/.config/serpantinum/settings.json` | `singletons/system/Config.qml` | settings should come from the widget's `shell.json` entry (`root.settings`) |
| `I18n.t(...)` (34 keys in the popup) | `singletons/system/I18n.qml` | Omarchy language must win; port keys into `i18n/*.json` |
| `WallpaperBlur` and `Wallpaper` singleton | `reusables/display/WallpaperBlur.qml` | the Omarchy background is `~/.config/omarchy/current/background` |
| Network: lyrics (NetEase, lrclib) and cover art (`i.ytimg.com`, `curl --max-time 4`) | `singletons/audio/Lyrics.qml:669-742`, `media/art_fetch.sh:95-156` | Omarchy rules: disclose, bound sizes, add a setting to turn it off |
| `Text` bound to metadata or lyrics | across `media/` and `reusables/media/` | must be `Text.PlainText` |

serpantinum-audio integration is all CLI, so it ports cleanly:

- `equalizer.sh` calls `serpantinum-audio ctl set|band|balance|…` and falls back to `serpantinum-audio start` (`equalizer.sh:72-77`). It seeds state from `${XDG_STATE_HOME:-~/.local/state}/serpantinum/audio.state`.
- The visualizer reads `serpantinum-audio visualizer` frames (`singletons/audio/Spectrum.qml`).
- The sink is named `serpantinum_sink`. The channel test uses `pw-play` and the sink check uses `pw-dump`.

## As built (2026-11-26)

These notes supersede the Design section below where they differ.

- **No QML singletons.**
  - `serp/SerpContext.qml` is a plain `Item` owned by each bar widget instance. It holds:
    - the theme roles derived from `Commons.Color` and `Style`
    - `tr()` over `Commons.Translations`, `s()` over `Style.spaceReal`, `playSfx()` and `installAudio()`
    - the services: `services/MprisController.qml`, `Spectrum.qml` and `Lyrics.qml`, ported from Serpantinum's singletons with explicit `mpris`/`serpDir`/`home` properties
  - Vendored views reach it through `serp/Serp.js` (`.pragma library`): `Serp.theme`, `Serp.mpris`, `Serp.lyrics`, `Serp.spectrum`, `Serp.tr`, `Serp.s` and `Serp.sfx`.
- **Quickshell gotcha:** a `.pragma library` file imported from `BarWidget.qml` and from files under `serp/` gives **two separate instances**, because of the `qs://` URL handling. So the context registers itself from inside `serp/` (`SerpContext.activate()` calls `Serp.use(root)`), never from `BarWidget.qml`. `BarWidget` calls `serpCtx.activate()` right before opening, and popup content only exists while open (a `Loader` bound to `popup.visible`). So `Serp.*` always points at the opening widget's context.
- **Mechanical port:** the vendored files keep upstream's folder layout under `serp/`. They were rewritten with these substitutions:

  | Upstream | Plugin |
  |---|---|
  | `ThemeBackend.` | `Serp.theme.` |
  | `I18n.t(` | `Serp.tr(` |
  | `Scaler.s(` | `Serp.s(` |
  | `Sounds.playSfx(` | `Serp.sfx(` |
  | `Caching.qsDir` / `Caching.serpantinumDir` | `Serp.theme.serpDir` |
  | `MprisController.` / `Lyrics.` / `Spectrum.` | `Serp.mpris.` / `Serp.lyrics.` / `Serp.spectrum.` |

  Imports of the upstream root become `import "<rel>/Serp.js" as Serp`. To sync upstream fixes, diff the same paths in Serpantinum from `714dd98` and apply them with these substitutions.
- **Glass:** `reusables/display/GlassFill.qml` and `GlassLens.qml` are inert stubs (`active: false`), so every control takes its non-glass path. `WallpaperBlur` was removed from `MusicPopup.qml`.
- **Host:**
  - Omarchy's `PopupCard` with `padding: 0` and `borderSpec: Border.none()` gives anchoring, click-away, bar-position handling and grow/fade.
  - The card's default property only accepts `Item`s, so a `Shortcut` must sit inside an `Item`.
  - Escape closes the popup, and Tab cycles tabs.
  - IPC target `ilyamiro.serpantinum-music` with `open`/`close`/`toggle` (`omarchy-shell ilyamiro.serpantinum-music toggle`).
- **Scale:** the popup is 20% smaller than upstream, to sit with Omarchy's UI.
  - `SerpContext.s()` is `Style.spaceReal(v) * uiScale` (0.8) and covers all geometry, including the popup's 625×565 size in `BarWidget.qml`.
  - Font sizes go through `fs()`, which is `max(9, Style.spaceReal(v) * fontScale)` with a font scale of 0.8.
  - Every `pixelSize`/`textFontSize`/`iconFontSize`/`fontPixelSize`/`minFontPixelSize`/`baseActiveFont`/`iconSize` set through `s()` was switched to `fs()`.
  - Widths that only hold text (the tab and dynamics switches, and the slack in the header action buttons' widths) use `fs()` too.
  - Hard-coded defaults that needed passing explicitly: Switch `horizontalPadding`, Toggle `trackWidth`/`trackHeight`, and ClickButton's icon-to-text gap (`Serp.s(8)`).
  - The two factors are separate so text can be tuned on its own. A 35% geometry cut was tried and found too small.
- **Radius:** `frameRadius` (outer frame, animated border) follows `Style.cornerRadius`. `borderRadius` (buttons, pills, sliders, toggles) is `max(Style.cornerRadius, 8)`, so controls stay rounded on square Omarchy themes.
- **Sounds:** the upstream click, toggle, switch, dropdown and swoosh `.wav` files live in `serp/assets/sounds/` and play through `pw-play`. The widget setting `sounds` (manifest schema, default on) turns them off. `reusables/button/click.wav` and `reusables/inputfield/error.wav` are referenced upstream but don't exist there either.
- **serpantinum-audio:**
  - `serp/scripts/install-audio.sh` is the installer's prebuilt path, installing to `~/.local/bin`. It's verified in the VM: 0.4.0 downloaded, checksum verified, daemon started.
  - `SerpContext.audioInstalled` is checked when the popup opens, and every 3 s while it's open and the daemon is missing.
  - `media/MusicAudioMissing.qml` covers the equalizer and audio tabs with an Install button. The button closes the popup and opens `omarchy-launch-floating-terminal-with-presentation`.
  - `serp/scripts/caching.sh` adds `~/.local/bin` to PATH for `equalizer.sh` and `art_fetch.sh`. The spectrum process does the same.
- **Upstream bug fixed here:** players that report embedded art as a `data:` URL (mpv-mpris) made `art_fetch.sh` fail to start, because the argument was too long. The URL now goes over stdin (`data:stdin` marker), and the script decodes it into `$QS_RUN_MUSIC/covers/embedded_<md5>.img`. Worth porting back to Serpantinum.
- **Safety:** every `Text` under `serp/` has `textFormat: Text.PlainText`. Verified with a track titled `<b>Bold</b><img src=…>`, which renders literally.
- **Art fetching** only runs while the popup is open (`MprisController.enabled`).
- **Translations:** `i18n/<code>.json` hold the 54 `music.*`, `guide.file_picker.*` and `guide.lyrics_picker.*` keys, generated from Serpantinum's 23 matching languages (`ua` becomes `uk`, `zh_tw` becomes `zh-TW`; `es`, `pt` and `zh` serve as base-language fallbacks). New plugin-only keys exist in `en.json` only.
- **Tab persistence:** popup content is rebuilt on every open, unlike Serpantinum's long-lived popout window. So the selected tab lives in `SerpContext.musicTab`, which `MusicBottomHeader`'s switch writes on change and reads as its initial index. `MusicPopup` seeds `actionBtnMorph`, `presetSlideProgress` and `audioHeaderProgress` from that index in `Component.onCompleted`, so the header buttons match the restored tab.
- **Lyrics file picker:** the Serpantinum `FilePicker`, `Input` and `CloseButton` components were dropped. `LyricsPicker.qml` is a thin wrapper that keeps the popup's interface and calls `SerpContext.pickLyricsFile()`.
  - **The flow:**
    1. The popup closes, because the dialog would steal Hyprland's focus grab anyway.
    2. `serp/scripts/pick-file.py` calls the XDG portal `org.freedesktop.portal.FileChooser.OpenFile` through Python GObject, which Omarchy ships. It uses the "Lyrics files" filter (`*.lrc`, `*.txt`) and a translated title, and prints the chosen path.
    3. The context reopens the popup, and after 400 ms calls `Lyrics.loadLocalLyricsFile()`, which caches the result.
  - **The process lives in the context,** not the popup, so it survives the popup closing.
  - **Portal crash:** the script exits if the portal's bus name disappears, so a crashed portal can't leave a request hanging and blocking the next one.
  - **Verified in the VM:** the GTK portal dialog opens, a chosen `.lrc` loads synced lyrics, Esc cancels cleanly, and the picker reopens.
  - **VM testing tip:** `wtype` named keys (Return, Escape, BackSpace) don't reach GTK4 dialogs. Use `sendkey ret` and `sendkey esc` over the QEMU monitor, and type text slowly (`wtype -d 90`) so the location bar's autocomplete doesn't eat characters.
- **Translations:**
  - `i18n/` covers all 50 Omarchy locales with 49 keys each. `es-MX`, `zh-CN` and `pt-BR` fall back to `es`, `zh` and `pt`.
  - The 22 languages Serpantinum already had keep its strings, plus the new install and picker strings. The other 27 were written for this plugin.
  - Verified live in Danish and Russian with `omarchy-language`.
  - The device pill's "Speaker" comes from `art_fetch.sh`, so it isn't translated (same upstream).
- **Executable bits matter:** `MusicEqualizerState.execCmd` runs `equalizer.sh` directly through `bash -c`, so `serp/media/*.sh` and `serp/scripts/*.sh` must stay mode 755, as they are upstream. Copied in as 644, every equalizer command failed with exit 126, so nothing was saved and the daemon stayed flat. Keep the modes when vendoring files, and keep them in git.
- **VM dev loop:**
  - Restart the shell after each deploy (`omarchy-restart-shell`). Hot reload keeps the last good build when a new one fails to load, which hides errors.
  - `qs log -p /usr/share/omarchy/shell` shows `Plugin widget … failed:` lines.
  - Hyprland 0.56 `hyprctl dispatch` takes Lua (`hl.dispatch(...)`), so launch test commands with the shell's environment instead.

Still to do: visualizer and equalizer checked by ear with real audio output, bar at bottom, left and right positions, the lyrics file picker, an online-lyrics and cover-art setting, update check on the equalizer page, README screenshots, translations of the new keys.

## Design

### Layout

```
manifest.json
BarWidget.qml            the Omarchy entry point: bar button + popup host
i18n/<lang>.json         plugin strings, including the ported Serpantinum keys
serp/                    vendored Serpantinum subtree, same relative layout as src/quickshell
  qmldir                 registers only the adapter and real singletons the popup uses
  media/ reusables/ singletons/
  scripts/               equalizer.sh, art_fetch.sh, a trimmed caching.sh
```

**Risk to check first:** on 4.5.0, omarchy-shell logs `WARN quickshell.qmlscanner: Module path "~/.config/omarchy/plugins/<id>" is outside of the config folder` for the plugin. Quickshell's scanner handles `pragma Singleton` and qmldir specially, and only inside the shell's config root. Before vendoring 35 files, prove that a plugin-local qmldir singleton resolves through `import "../"` from a subfolder. If it doesn't, the adapter singletons become plain `QtObject`s instantiated once in `BarWidget.qml` and passed down, or registered through `Qt.createComponent` and a shared JS module.

Keeping `serp/` in the same shape as `src/quickshell` means the vendored files keep their `import "../"` lines unchanged. Upstream fixes can then be pulled with `git diff 714dd98..HEAD -- <closure paths>` from the Serpantinum repo. Files are copied, never symlinked, because the validator rejects symlinks.

### Adapter singletons (replacing Serpantinum's, same names and properties)

- **ThemeBackend:** derives the Catppuccin-style roles the popup reads from the Omarchy theme:
  - `base` ← `Commons.Color.popups.background`
  - `text` ← `Commons.Color.popups.text`
  - `mauve` and `blue` ← `Commons.Color.accent`
  - `red` ← `Commons.Color.urgent`
  - `surface0..2` and `overlay0..2` ← mixes of background toward foreground at fixed ratios
  - `fontFamily` ← `Style.font.family`
  - `borderRadius` ← `Style.cornerRadius`

  The popup reads `mauve` 40×, `surface0` 24×, `elementOpacity` 21×, `borderRadius` 20× and `fontFamily` 19×. An optional setting, `useSerpantinumTheme`, reads Serpantinum's matugen colours when they exist, for people running both.
- **Caching:** `qsDir` becomes the plugin's `serp/` folder, from `Qt.resolvedUrl`. State, cache and run directories stay under the XDG `serpantinum` folders, so the equalizer state is shared with a real Serpantinum install.
- **Config:** a thin wrapper over the widget's `settings` with defaults. Settings are declared in `manifest.json` `barWidget.defaults` and `schema`.
- **I18n:** forwards `t(key, fallback)` to the plugin's `Commons.Translations`. Translations for the 34 keys are copied from `src/assets/languages/` into Omarchy language codes.
- **Scaler:** maps to `Style.space()`, so Omarchy's spacing and font scale apply.
- **Wallpaper:** points at the Omarchy background symlink and watches it for theme or background changes.
- Drop `Sounds`, `FocusTimer`, `Matugen` and `AppTheming` unless something the popup actually needs uses them.

### Popup host

Serpantinum's popup draws its own frame (`MusicBorder`, `MusicBlurCrossfader`, `WallpaperBlur`). `PopupCard` adds a second border and padding around its content.

- **Preferred:** host `MusicPopup` in its own `PopupWindow` anchored to the widget. It keeps Serpantinum's chrome and size, and copies `PopupCard`'s grow-and-fade motion and click-away close.
- **Fallback:** if the coordinator close behaviour can't be matched, put it inside `PopupCard` with `padding: 0` and Serpantinum's border disabled.

Decide after the first look in the VM.

### MPRIS

Keep Serpantinum's own `MprisController` and `Quickshell.Services.Mpris`, since `omarchy.media` isn't reachable from a third-party plugin. The bar button can optionally show the scrolling title like `omarchy.media`.

### serpantinum-audio dependency

`omarchy plugin add` never runs install hooks or sudo, so the daemon is installed by a script the plugin ships. AUR registrations are closed, so there's no AUR route. The script ports the prebuilt path of Serpantinum's installer (`install/modules/audio.sh`, `audio_install_prebuilt`):

- `serp/scripts/install-audio.sh`:
  - pins `VERSION` and a SHA-256 digest per architecture in the script (marketplace security review on submission #16032: never trust `releases/latest` or the release's own `SHA256SUMS`)
  - downloads `releases/download/v<ver>/serpantinum-audio-<ver>-<x86_64|aarch64>-linux.tar.gz`
  - verifies it against the pinned digest before extracting or running anything
  - checks that `usr/bin/serpantinum-audio version` runs
  - installs to `~/.local/bin/serpantinum-audio` (and the license to `~/.local/share/licenses/serpantinum-audio/`) without sudo, then runs `serpantinum-audio start`

  It skips the install when the installed `version` already matches the pinned version. Moving to a new serpantinum-audio release means updating `VERSION` and both digests and bumping the manifest version. v0.4.0 has assets for both architectures, built on GitHub's Ubuntu runners, so the glibc is older than Arch's.
- Omarchy puts `~/.local/bin` on PATH (`default/bash/envs:44`, `default/bash/env-bootstrap:61`). The plugin still resolves the binary as `command -v serpantinum-audio`, falling back to `~/.local/bin/serpantinum-audio`, in case the shell started with a narrower PATH. This also picks up an existing `/usr/local/bin` install from the Serpantinum installer.
- Detection: when the binary is missing, the equalizer page shows a short "serpantinum-audio isn't installed" state with an **Install** button, and the visualizer falls back to a static bar.
- The button opens a terminal running the script, never a hidden download. Omarchy's own plugin `add`/`clone` opens a terminal for the same reason, and its safety rules forbid silently executing downloaded content. The README documents the same script as a one-liner for people who prefer to run it themselves.
- Updates: serpantinum-audio updates ship only as plugin updates that change the pins.

## Test environment: Omarchy VM

Host: NixOS with KVM and QEMU 11.1. It has an AMD iGPU (`renderD128`, amdgpu, PCI `04:00.0`) alongside NVIDIA (`renderD129`), 16 cores, 15 GiB RAM and 159 GiB free.

The VM runs from plain QEMU through `${XDG_DATA_HOME:-~/.local/share}/serp-omarchy-vm/vm.sh` rather than libvirt. That avoids system-libvirt permissions on the home directory and session-libvirt's need for passt to forward ports. The script sets up:

- a q35 machine with OVMF (`edk2-x86_64-code.fd` + a copy of `edk2-i386-vars.fd`)
- 4 vCPUs, 8 GiB RAM, a 40 GiB qcow2 disk
- `virtio-vga-gl` at 1920×1080, displayed through SDL with GL on (GTK with GL draws the guest shifted up on this host)
- guest audio through PipeWire (intel-hda), needed for the music popup and serpantinum-audio
- SSH on `127.0.0.1:2222`

Commands: `vm.sh install`, `vm.sh run`, `vm.sh snapshot|restore NAME` (qcow2 internal snapshots, VM off) and `vm.sh ssh [cmd]`.

1. ISO: `https://iso.omarchy.org/omarchy-4.5.0-x86.iso` plus `.sig`, downloaded to `${XDG_DATA_HOME:-~/.local/share}/serp-omarchy-vm/`.
2. Unattended install (`manual/51-unattended-installs.md`): a `cidata` ISO with `user_configuration.json`, `user_credentials.json` (`openssl passwd -6`) and `authorized_keys`. The installer skips the wizard and enables sshd. The first run may need to be interactive to capture `user_configuration.json`; copy it from `/root` afterwards.
3. The first boot is `vm.sh install`, which attaches the ISO. After the install, `vm.sh snapshot clean`, then `vm.sh run` from then on.
4. Dev loop:
   - `rsync -a --delete` this repo into the VM's `~/.config/omarchy/plugins/ilyamiro.serpantinum-music/`. Hot reload picks it up.
   - Run `omarchy plugin validate`, `omarchy agent look plugin` and `omarchy bar put ilyamiro.serpantinum-music` over SSH.
   - Take screenshots with `grim` over SSH (`WAYLAND_DISPLAY` from the user session) and pull them back to inspect.
   - Read logs with `journalctl --user` or the omarchy-shell log for QML errors.
5. Test serpantinum-audio in the VM through the plugin's own `install-audio.sh`, starting from a clean snapshot, so the install button, the equalizer, the visualizer and the no-daemon state are all exercised.
6. Snapshot the VM after install (`virsh snapshot-create-as`) so it can be reset to a clean Omarchy.

## Implementation checklist

1. **Stub install (done 2026-11-26 on the VM, Omarchy 4.5.0-3):** `omarchy plugin validate` passes, `omarchy bar put ilyamiro.serpantinum-music --section centerBegin` places it, and the note button renders left of the clock with no QML errors. `omarchy agent look plugin` doesn't exist in 4.5.0, so use `grim` screenshots instead. Still to confirm: the placeholder card opens on click.
1a. **Singleton spike:** see the risk under Layout.
2. **Vendor the closure into `serp/`:** copy only real dependencies (re-run the closure check, prune the `Timer` false positives). Verify: every `import` resolves, with no `qs.` imports inside `serp/` and no symlinks.
3. **Adapter singletons:** ThemeBackend, Caching, Config, I18n, Scaler and Wallpaper. Verify: `omarchy agent look plugin` shows no QML errors. Switch the Omarchy theme and check the popup recolours live.
4. **Popup host window:** mount `MusicPopup` from `BarWidget.qml` and match the open and close motion and click-away. Verify: it opens from the bar at top, bottom, left and right positions, and closes on outside click and Esc.
5. **Scripts:** trim `caching.sh`, make `equalizer.sh` and `art_fetch.sh` resolve from the plugin folder and run them through `bash` explicitly. Verify: EQ presets, single bands, balance, mono, swap, dynamics and dynamic EQ all reach the daemon (`serpantinum-audio ctl get` matches the UI).
6. **No-daemon path and installer:** on a clean VM snapshot, open the equalizer page. Verify: the popup opens, the install state shows and nothing logs errors in a loop. The **Install** button opens a terminal, the checksum is verified, `~/.local/bin/serpantinum-audio version` matches the pinned version, and the equalizer comes alive without restarting the shell. A tampered digest (edit the pin in a test copy) must abort before installing.
7. **Safety pass:** `Text.PlainText` on every metadata or lyrics sink. Add a `lyricsOnline` / `coverArtOnline` setting (default on, disclosed in the description). Bound response sizes. Verify: a track titled `<img src=https://example.invalid/x>` renders literally.
8. **Translations:** move the 34 keys into `i18n/en.json` and the other languages. Verify: switching the Omarchy language changes the popup live.
9. **Motion and reduced motion:** route durations through `Style.duration`. Verify: `omarchy toggle animations` disables them.
10. **Polish for the marketplace:** README with screenshots and GIF, `barWidget.schema` for settings, a version tag. List it on plugins.omarchy.org.

## Open questions

- Should the bar button stay an icon, or show the scrolling title like `omarchy.media` and replace it?
- Contest #3 isn't announced. Contest #2's rules were one prize per GitHub account, PayPal payouts, community vote, and the plugin had to be available when voting closed. Ship early enough to be listed on plugins.omarchy.org before the next one opens.
