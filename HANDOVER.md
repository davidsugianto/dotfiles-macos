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
  is even with `origin/main` through commit `79737e7` — nothing below has
  been pushed.
- **Uncommitted changes** (repo convention: only commit when asked) — a
  multi-session push turning Neovim into a full IDE, plus the doc/install
  updates to match:
  - `nvim/lua/plugins/explorer.lua`, `bufferline.lua` (new),
    `winbar.lua` (new), `colorscheme.lua` — Neo-tree now auto-opens on
    startup docked left, bufferline tab bar added, dropbar.nvim breadcrumb
    winbar added.
  - `nvim/lua/plugins/lsp.lua`, `treesitter.lua`, `formatting.lua` (new),
    `linting.lua` (new), `mason-tools.lua` (new) — full LSP/format/lint for
    Lua, Bash, C/C++, Go, Node/TS/JS, Python, YAML, JSON, Terraform. All
    verified installed and attaching correctly via real interactive tmux
    sessions (see OPERATIONS.md's headless-mode gotcha for why not
    headless).
  - `nvim/lua/config/keymaps.lua` — buffer-cycling keymaps moved into
    `plugins/bufferline.lua`, removed the duplicates here.
  - `setup.sh` — added `wget` to the base formula list (mason's clangd
    installer hard-requires it, no curl fallback; this was missing and
    would silently fail clangd installs on a fresh clone).
  - `README.md`, `OPERATIONS.md` — updated to describe the IDE setup, the
    OpenTofu-not-Terraform / Go-runtime prerequisites for the new language
    servers, the current keybinding table, and the new gotchas below. Also
    added a `## Prerequisites` section ahead of Install: `xcode-select
    --install` (Command Line Tools) is the actual first step on a
    completely fresh Mac — `git clone` (the first command Install itself
    tells you to run) doesn't work without it. Homebrew is documented there
    too, but as optional/FYI, not a required manual step — `setup.sh`
    already installs it automatically if missing, so telling readers to
    install it by hand would've contradicted that.
  - This is intended as a finalized, coherent state — not mid-refactor.
- System-level changes made on **this machine** to support the above (not
  tracked in git, so a fresh machine won't have them until it hits the same
  wall and needs the same fix — `wget` is now in `setup.sh` so that part
  self-heals, but Go's version doesn't):
  - Installed Go 1.26.6 via `gvm` and made it active (gopls needs it;
    go1.25.0 is still installed too — `gvm use 1.25.0` to switch back).
  - Installed `wget` via brew directly (now redundant with the `setup.sh`
    change above, just documenting that this machine already has it).

## Open items / unanswered questions

- None currently open. Everything from this session's language-support work
  landed and was verified; the docs were updated to match. Next natural
  step, if the user wants it, is committing — ask first per this repo's
  convention.

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
