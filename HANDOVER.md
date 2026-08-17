# Handover

Session-to-session continuity notes for this repo. If you're a new Claude
Code session picking this up, read this first — it's the "what's mid-flight"
doc, distinct from [OPERATIONS.md](OPERATIONS.md) (how to run/maintain,
including the full known-gotchas list) and [README.md](README.md) (what this
is / how to install).

**Keep this file updated** as work happens — it's meant to reflect the
current state, not the history (that's what git log is for). Permanent
knowledge (gotchas, keybindings, conventions) belongs in OPERATIONS.md/
README.md instead — move it there and trim it out of here once it's settled,
so this file stays a snapshot of what's in flight, not an ever-growing log.

## Repo state as of last update

- Remote: `github.com/davidsugianto/dotfiles-macos` (public). Local `main`
  is even with `origin/main` through commit `9745e0b` — pushed, working
  tree clean, nothing in flight.
- What landed in the last two commits (`cd7c554`, `9745e0b`): turned
  Neovim into a full IDE — Neo-tree (auto-opens on startup, docked left),
  bufferline tab bar, dropbar.nvim breadcrumb winbar, and mason-managed
  LSP/format/lint for Lua, Bash, C/C++, Go, Node/TS/JS, Python, YAML,
  JSON, and Terraform (Terraform tooling targets `tofu`, not `terraform` —
  see OPERATIONS.md's gotcha). `setup.sh` gained a `wget` dependency
  (mason's clangd installer needs it) and a `## Prerequisites` section
  (Xcode Command Line Tools, Homebrew as optional/FYI). Full detail is in
  `git log -p cd7c554 9745e0b` / the commit messages themselves — not
  worth re-duplicating here now that it's shipped; see OPERATIONS.md for
  the permanent version (keybindings, gotchas, update commands).
- System-level changes made on **this machine** that git doesn't track (a
  fresh machine won't have them until it hits the same wall and fixes it
  the same way — `wget` now self-heals via `setup.sh`, but the Go version
  doesn't):
  - Go 1.26.6 installed via `gvm` and made active (gopls needs it;
    go1.25.0 is still installed too — `gvm use 1.25.0` to switch back).

## Open items / unanswered questions

- None currently open.

## Standing conventions this repo follows

- One folder per tool at repo root; `setup.sh` installs + symlinks
  everything; `development-tools.sh` is a separate optional DevOps layer.
- Theme is Catppuccin Mocha, hand-rolled per tool (not via external theme
  package managers, except where officially blessed).
- Every change gets validated live on this actual machine (syntax check +
  reload + query the running tool) before being reported as done — not
  just written and assumed correct. For Neovim specifically, that means a
  real interactive session (tmux), not headless `-c` command chains — see
  OPERATIONS.md's Known gotchas.
- Only commit/push to git when the user explicitly asks.
- Before reaching for a tool/package by its "obvious" name (terraform,
  docker, etc.), check `development-tools.sh` and `setup.sh` first — this
  repo has already made a deliberate substitution more than once (OpenTofu
  over Terraform, Colima over Docker Desktop, gvm over Homebrew's `go`).
