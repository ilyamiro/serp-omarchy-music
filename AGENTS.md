# serp-omarchy-plugin — agent guide

An Omarchy shell plugin (`ilyamiro.serpantinum-music`) that ships the Serpantinum music popup inside `omarchy-shell`. The upstream source is the Serpantinum repo (`~/Projects/serpantinum`). Vendored files under `serp/` mirror `src/quickshell/` and record the Serpantinum commit they came from.

## Rules

- Follow Omarchy's plugin rules (`default/agents/skills/omarchy-make-plugin/SKILL.md` in Omarchy):
  - strings in `i18n/<lang>.json` via `Commons.Translations`
  - `Text.PlainText` for any untrusted text
  - durations via `Style.duration()`
  - `Commons.Color` for theme colours
- No symlinks anywhere in the repo, because `omarchy plugin validate` rejects them.
- Never hardcode visible text. UI strings use sentence case.
- Never leave explanatory comments or change markers in edited files.
- Conventional one-line commit messages (`feat:`, `fix:`, `refactor:`, …) with no AI attribution.
- Test in the Omarchy VM, never on the host session.

## Plans

`.agents/plans/` holds implementation plans with their baseline commits. Re-verify referenced paths against the current Serpantinum and Omarchy sources before acting on one.
