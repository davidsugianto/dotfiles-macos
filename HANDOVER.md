# Handover

Session-to-session continuity notes for this repo. If you're a new Claude
Code session picking this up, read this first — it's the "what's mid-flight"
doc, distinct from [OPERATIONS.md](OPERATIONS.md) (how to run/maintain) and
[README.md](README.md) (what this is / how to install).

**Keep this file updated** as work happens — it's meant to reflect the
current state, not the history (that's what git log is for).

## Repo state as of last update

- Remote: `github.com/davidsugianto/dotfiles-macos` (public), pushed once
  as the initial commit (`06a9aa4`).
- **Uncommitted changes since that commit** (not yet pushed):
  `OPERATIONS.md` (new), `README.md`, `aerospace/aerospace.toml`,
  `development-tools.sh`, `starship.toml`, `zsh/aliases.zsh`. Run
  `git status` / `git diff` to see exactly what, then ask the user before
  committing — this repo's convention has been "only commit when asked."

## Open items / unanswered questions

- README's DevOps toolchain table doesn't list colima/docker/docker-compose
  yet (added to `development-tools.sh` but not documented in `README.md`)
  — asked the user, no answer yet.

## Standing conventions this repo follows

- One folder per tool at repo root; `setup.sh` installs + symlinks
  everything; `development-tools.sh` is a separate optional DevOps layer.
- Theme is Catppuccin Mocha, hand-rolled per tool (not via external theme
  package managers, except where officially blessed).
- Every change gets validated live on this actual machine (syntax check +
  reload + query the running tool) before being reported as done — not
  just written and assumed correct. Several real bugs were only caught this
  way (see OPERATIONS.md "Known gotchas").
- Only commit/push to git when the user explicitly asks.
