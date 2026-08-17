# Handover

Session-to-session continuity notes for this repo. If you're a new Claude
Code session picking this up, read this first — it's the "what's mid-flight"
doc, distinct from [OPERATIONS.md](OPERATIONS.md) (how to run/maintain) and
[README.md](README.md) (what this is / how to install).

**Keep this file updated** as work happens — it's meant to reflect the
current state, not the history (that's what git log is for).

## Repo state as of last update

- Remote: `github.com/davidsugianto/dotfiles-macos` (public). Local `main`
  is in sync with `origin/main` (not ahead/behind) — everything through
  commit `97e0666` is pushed.
- **Uncommitted changes** (not yet pushed): `OPERATIONS.md`, `starship.toml`,
  `wezterm/config/appearance.lua`, `tmux/tmux.conf.local`,
  `nvim/lua/plugins/statusline.lua`. Run `git status` / `git diff` to see
  exactly what, then ask the user before committing — this repo's
  convention has been "only commit when asked."
- What that diff is: a cohesive Catppuccin Mocha "powerline" pass across
  the whole terminal stack, built up incrementally against reference
  screenshots the user provided —
  - `starship.toml`: full rewrite from a flat/minimal prompt to connected
    pill segments (os/user → directory → git → runtime versions → time),
    rounded caps at the very start/end, sharp chevron separators between,
    directory truncated to 1 level (`…/reponame`).
  - `wezterm/config/appearance.lua`: cursor changed from a block to a bar,
    explicit rosewater (`#f5e0dc`) color instead of relying on the builtin
    scheme.
  - `tmux/tmux.conf.local`: active/last-window highlight recolored to the
    same rosewater accent (pane borders deliberately left mauve, matching
    JankyBorders — see the inline comment), and the window-list chevron
    separator turned back on (it was explicitly disabled before).
  - `nvim/lua/plugins/statusline.lua`: lualine rebuilt with the same
    rounded/chevron separator language, plus new LSP-client-name and
    git-repo-name components.

## Open items / unanswered questions

- README's DevOps toolchain table doesn't list colima/docker/docker-compose
  yet (added to `development-tools.sh` but not documented in `README.md`)
  — asked the user, no answer yet.

## Non-obvious things learned this session (see OPERATIONS.md for full detail)

- **A real, pre-existing bug got fixed along the way**: `nvim/lua/plugins/statusline.lua`'s
  `theme = "catppuccin"` was never a valid lualine theme name — lualine has
  no bundled theme by that name, so it was silently falling back to
  lualine's generic `"auto"` theme the whole time, not real Catppuccin
  colors. The real theme lives inside catppuccin.nvim itself, at
  `lualine.themes.catppuccin-mocha`.
- **Typing a literal Nerd Font Private-Use-Area glyph (Powerline
  separators, older Devicons/FontAwesome icons) directly into a file via
  Write/Edit can silently drop the character**, no error — this bit
  `starship.toml` badly enough to need a byte-level hexdump investigation
  to diagnose. Workaround differs by file type: TOML supports `\uXXXX`
  escapes natively; oh-my-tmux (`tmux.conf.local`) self-decodes `\uXXXX`
  via its own `_decode_unicode_escapes`; Neovim's Lua (LuaJIT) has no
  `\u{XXXX}` string escape at all, so use `vim.fn.nr2char(0xXXXX, true)`
  instead. Full writeup + verification commands in OPERATIONS.md's Known
  gotchas — read that before touching any icon/separator glyph in this
  repo again.

## Standing conventions this repo follows

- One folder per tool at repo root; `setup.sh` installs + symlinks
  everything; `development-tools.sh` is a separate optional DevOps layer.
- Theme is Catppuccin Mocha, hand-rolled per tool (not via external theme
  package managers, except where officially blessed).
- Every change gets validated live on this actual machine (syntax check +
  reload + query the running tool) before being reported as done — not
  just written and assumed correct. Several real bugs were only caught this
  way (see OPERATIONS.md "Known gotchas"). For glyph/separator changes
  specifically, "validated" means confirming the actual codepoint via
  hexdump or `char2nr`/`nr2char`, not eyeballing the file — displaying a
  correctly-written glyph back to the assistant is itself unreliable (see
  above).
- Only commit/push to git when the user explicitly asks.
