# Operations

Day-to-day maintenance for this setup, once it's installed. README covers
first-time install; this covers what to do afterwards.

## Reloading after a config change

Most configs are symlinked, so an edit takes effect on next reload — no
`setup.sh` re-run needed unless you added a new file/symlink or a new
package.

| Tool | Command |
|---|---|
| AeroSpace | `aerospace reload-config` (auto-reloads on save too) |
| SketchyBar | `sketchybar --reload` (alias: `sbr`) |
| Borders | `brew services restart borders` (alias: `bdr`) |
| tmux | `tmux source-file ~/.config/tmux/tmux.conf` (alias: `tmr`) — only affects already-running sessions; new sessions pick it up automatically |
| WezTerm | Auto-reloads on save (`automatically_reload_config = true`) |
| Neovim | Restart, or `:source $MYVIMRC` for `lua/config/*` changes. Plugin spec changes need `:Lazy sync` |
| zsh | `exec zsh` (alias: `reload`) |
| Starship | Auto-reloads on next prompt draw |

## Modifying configs

Where to make changes for the three tools people customize most often, and
how to validate them live afterwards (per this repo's convention — don't
just edit and assume correct).

### AeroSpace

- Keybindings live in `aerospace/aerospace.toml` under `[mode.main.binding]`
  (normal mode) and `[mode.resize.binding]` (the `alt-r` resize mode). Add a
  line like `alt-x = 'some-command'`.
- Workspace bindings come in pairs — `alt-N = 'workspace N'` (switch) and
  `alt-shift-N = ['move-node-to-workspace N', 'workspace N']` (move-and-follow).
  Add both halves if you add a new workspace number, or you'll get a
  switch with no matching move.
- Per-app rules (float/pin an app, send it to a workspace) go in
  `[[on-window-detected]]` blocks near the bottom of the file.
- Reload: auto-reloads on save, or `aerospace reload-config`. Validate with
  `aerospace list-workspaces --monitor all` or by actually triggering the
  new binding — don't just eyeball the TOML.
- Remember: `#` for comments, not `--` (see Known gotchas below).

### tmux

- Never edit `tmux.conf` itself — it's symlinked straight from the vendored
  oh-my-tmux clone and gets overwritten on refresh. All local changes go in
  `tmux/tmux.conf.local`. Append `#!important` to a line if you need to
  override something `tmux.conf` sets unconditionally.
- The top of `tmux.conf.local` sets oh-my-tmux's `tmux_conf_*` variables
  (theme, colors, behavior toggles) — prefer setting one of those over raw
  tmux commands if oh-my-tmux already exposes it.
- Custom keybindings or anything oh-my-tmux doesn't expose as a variable go
  under the `-- user customizations --` section at the bottom, in plain
  tmux syntax (`set -g ...`, `bind ...`).
- Reload: `tmux source-file ~/.config/tmux/tmux.conf` (alias `tmr`) — only
  affects already-running sessions, new sessions pick it up automatically.
  Validate by triggering the binding or checking `tmux show-options -g` in
  a live session.

### Neovim

- Keymaps not tied to a specific plugin: `nvim/lua/config/keymaps.lua`.
  Plugin-specific keymaps live inside that plugin's own spec file in
  `nvim/lua/plugins/`, not in `keymaps.lua`.
- New plugin: add a spec table to an existing file in `nvim/lua/plugins/`,
  or a new file — lazy.nvim auto-loads every file that returns a spec from
  that directory (see `nvim/lua/config/lazy.lua`). Run `:Lazy sync` to
  install it.
- New LSP server: add its name to `ensure_installed` in the
  `mason-lspconfig.nvim` block of `nvim/lua/plugins/lsp.lua`, then restart
  Neovim — mason installs it automatically. Give it non-default settings
  via `vim.lsp.config("<server>", { ... })` in that same file's `config`
  function (see the `lua_ls` example already there).
- Reload: `:source $MYVIMRC` picks up `lua/config/*.lua` edits; plugin spec
  changes (new plugin, changed `opts`) need `:Lazy sync`, not just a
  reload. Validate with `:LspInfo` / `:Lazy` or by actually triggering the
  new keymap, not just by re-reading the file.

## Keybinding reference

Current bindings as configured in this repo (not upstream defaults). If you
add/change a binding per "Modifying configs" above, update the matching
table here too — it drifts otherwise.

### AeroSpace

Modifier is `alt` throughout. Defined in `aerospace/aerospace.toml`.

| Key | Action |
|---|---|
| `alt-h/j/k/l` | Focus left/down/up/right |
| `alt-shift-h/j/k/l` | Move focused window left/down/up/right |
| `alt-minus` / `alt-equal` | Resize smaller/larger |
| `alt-slash` | Layout: tiles |
| `alt-comma` | Layout: accordion |
| `alt-f` | Fullscreen |
| `alt-shift-space` | Toggle floating/tiling |
| `alt-shift-g` | Join focused window with the one below into a container |
| `alt-shift-t` | "Tab" with window below (join + accordion) |
| `alt-1`…`alt-9` | Switch to workspace 1–9 |
| `alt-shift-1`…`alt-shift-9` | Move focused window to workspace 1–9 and follow |
| `alt-tab` | Jump to previously focused workspace |
| `alt-shift-,` / `alt-shift-.` | Focus previous/next monitor |
| `alt-r` | Enter resize mode |
| `alt-shift-c` | Reload config |

Resize mode (after `alt-r`): `h`/`l` width, `j`/`k` height, `enter`/`esc` back to main mode.

### tmux

Prefix is `C-b` (unchanged tmux default). Defined via oh-my-tmux
(`~/.local/share/tmux/oh-my-tmux/.tmux.conf`, vendored) plus overrides in
`tmux/tmux.conf.local`. `<prefix>` below means `C-b` first, then the key;
`-n` means no prefix needed.

| Key | Action |
|---|---|
| `<prefix> r` | Reload config |
| `<prefix> e` | Edit `tmux.conf.local` in `$EDITOR`, reload on save |
| `<prefix> -` / `_` | Split pane vertically/horizontally |
| `<prefix> h/j/k/l` | Move to pane left/down/up/right (repeatable) |
| `<prefix> H/J/K/L` | Resize pane (repeatable) |
| `<prefix> >` / `<` | Swap pane with next/previous |
| `<prefix> +` | Maximize/restore current pane |
| `<prefix> C-h` / `C-l` | Previous/next window (repeatable) |
| `<prefix> C-S-h` / `C-S-l` | Swap window with previous/next |
| `<prefix> Tab` | Jump to last active window |
| `<prefix> 0` | Select window at index 10 |
| `<prefix> BTab` | Switch to last session |
| `<prefix> C-c` | New session |
| `<prefix> C-f` | Find/switch session by name |
| `<prefix> Enter` | Enter copy mode (vi-style: `v` select, `C-v` rectangle, `y` copy+exit, `H`/`L` line start/end, `Esc` cancel) |
| `<prefix> m` | Toggle mouse on/off |
| `<prefix> b` / `p` / `P` | List / paste / choose paste buffer |
| `<prefix> F` | Open pane's CWD in fpp |
| `-n C-a` | Pass literal `C-a` through to shell (tmux prefix stays `C-b`; `C-a` is WezTerm's leader) |
| `-n C-l` | Clear screen + scrollback |

Standard unmodified tmux defaults still apply (`<prefix> c` new window,
`<prefix> ,` rename, `<prefix> %`/`"` split, `<prefix> d` detach, `<prefix> z`
zoom, `<prefix> :` command prompt, `<prefix> ?` list all keys).

### Neovim

Leader is `<space>` (`nvim/lua/config/options.lua`). Global keymaps in
`nvim/lua/config/keymaps.lua`; plugin keymaps live next to their plugin spec.

| Key | Action | Source |
|---|---|---|
| `<C-h/j/k/l>` | Focus window left/down/up/right | `config/keymaps.lua` |
| `<C-Up/Down/Left/Right>` | Resize split | `config/keymaps.lua` |
| `<S-l>` / `<S-h>` | Next/previous buffer | `config/keymaps.lua` |
| `<leader>bd` | Delete buffer | `config/keymaps.lua` |
| `<esc>` | Clear search highlight | `config/keymaps.lua` |
| `<leader>w` / `<leader>q` | Save / quit | `config/keymaps.lua` |
| `<leader>e` | Toggle file explorer (Neo-tree) | `plugins/explorer.lua` |
| `<leader>ff/fg/fb/fh/fr` | Telescope: find files / grep / buffers / help / recent files | `plugins/telescope.lua` |
| `]h` / `[h` | Next/previous git hunk | `plugins/git.lua` |
| `<leader>hp/hs/hr` | Preview/stage/reset git hunk | `plugins/git.lua` |
| `gd` / `gr` | Go to definition / references | `plugins/lsp.lua` (buffer-local, on `LspAttach`) |
| `K` | Hover docs | `plugins/lsp.lua` |
| `<leader>rn` | Rename symbol | `plugins/lsp.lua` |
| `<leader>ca` | Code action | `plugins/lsp.lua` |
| `<leader>e` | Line diagnostics | `plugins/lsp.lua` (buffer-local, on `LspAttach`) |

**Known conflict:** `<leader>e` is bound twice — globally to Neo-tree toggle
(`plugins/explorer.lua`) and buffer-locally to line diagnostics on
`LspAttach` (`plugins/lsp.lua`). The buffer-local one wins in any buffer
with an LSP client attached, so `<leader>e` opens diagnostics there instead
of toggling the explorer. Not yet reconciled — rebind one if it bites you.

## Updating everything

```sh
brew update && brew upgrade   # alias: brewup
```

Then, separately (these don't move with `brew upgrade`):
- **Neovim plugins**: open nvim, `:Lazy sync`
- **Go itself** (if you installed it): `gvm upgrade && gvm install latest`
- **tmux/SketchyBar/oh-my-tmux vendored code**: see below, these are frozen at whatever commit `setup.sh` last cloned

## Vendored dependencies

A few things aren't Homebrew packages — `setup.sh` clones/downloads them
once and never touches them again on subsequent runs (idempotent by
design). To pick up upstream changes, delete and re-run `setup.sh`:

| What | Where | Refresh with |
|---|---|---|
| SbarLua (SketchyBar's Lua API) | `~/.local/share/sketchybar_lua` | `rm -rf ~/.local/share/sketchybar_lua && ./setup.sh` |
| Oh my tmux! | `~/.local/share/tmux/oh-my-tmux` | `rm -rf ~/.local/share/tmux/oh-my-tmux && ./setup.sh` (then `git -C ~/.local/share/tmux/oh-my-tmux pull` also works, without a full re-clone) |
| sketchybar-app-font icon map | `~/.local/share/sketchybar/icon_map.lua` | `rm ~/.local/share/sketchybar/icon_map.lua && ./setup.sh` |
| gvm (Go version manager) | `~/bin/gvm` | `gvm upgrade` (self-updates in place, no need to delete) |

## Homebrew tap trust

Homebrew gates formulae/casks from third-party taps behind a trust check.
`setup.sh` trusts exactly what this repo uses (not the whole tap) on every
run:

```sh
brew trust --formula felixkratz/formulae/borders felixkratz/formulae/sketchybar
brew trust --formula anomalyco/tap/opencode
brew trust --cask nikitabobko/tap/aerospace
```

If you ever see `Refusing to load formula ... from untrusted tap` (this can
resurface after a Homebrew self-update resets trust state), re-run
`setup.sh` — that step is idempotent — or run the commands above directly.

## Known gotchas

- **`brew` download resumes can silently corrupt**: if a cask download
  fails partway with a `curl: (56) Recv failure`, don't just retry — clear
  the partial file first (`rm` the `.incomplete` file under
  `~/Library/Caches/Homebrew/downloads/`) or the resumed download can stall
  at the exact same byte offset every time. `brew install --cask <name>`
  again after clearing.
- **TOML files use `#` for comments, not `--`** — easy mistake to make
  when you're bouncing between editing `aerospace/aerospace.toml` (TOML)
  and the `.lua` files in the same session. A `--` in a `.toml` file is a
  syntax error, not a comment.
- **`nvim-treesitter` and `nvim-lspconfig` moved to new APIs** (Neovim
  0.11+): `require('nvim-treesitter.configs')` and
  `require('lspconfig').<server>.setup()` are gone/deprecated. This repo's
  `nvim/lua/plugins/{treesitter,lsp}.lua` already use the current
  `vim.treesitter.start()` / `vim.lsp.config()` APIs — if you see either of
  those errors, something reverted, not upstream.
- **`sketchybar-app-font` needs the font assigned as a bare string**, e.g.
  `font = "sketchybar-app-font:Regular:12.0"`, not
  `font = { family = "..." }` — the table form silently renders literal
  `:app_name:` text instead of the icon glyph.
- **A Claude Code session typing a literal Nerd Font Private-Use-Area glyph
  into a file via Write/Edit can silently drop the character**, with no
  error — the file ends up with an empty `""`/`[]` where the icon should
  be. Affects the older 3-byte BMP PUA range (U+E000–U+F8FF: Powerline
  separators U+E0B0–U+E0B7, Devicons/FontAwesome icons like git-branch
  U+E725 or Node.js U+E718). Newer 4-byte Supplementary-PUA-A icons
  (Material Design Icons, used elsewhere in `starship.toml`'s
  `[os.symbols]`/`[time]`) are *not* affected. Workaround: write it as a
  TOML `\uXXXX` escape (4 hex digits, no braces) instead of the literal
  character — verify with
  `python3 -c "import tomllib; print(tomllib.load(open('starship.toml','rb')))"`
  or a hexdump, not by eyeballing the file, since displaying a
  correctly-written glyph back to the assistant is also unreliable. Hit
  this in this repo's `starship.toml`; `sketchybar/icons.lua` already used
  Lua-style `\u{XXXX}` escapes for exactly this reason.

## Backups

`setup.sh` never deletes a file it's about to symlink over — it moves the
original to `~/.dotfiles-backup/<timestamp>/` first. Check there if
something you expected to still exist seems to have vanished after running
setup.

## git identity switching

Handled by `git/.gitconfig`'s `includeIf`, not something you set per-repo:

- `~/Artifacts/labs/**` → personal identity (`git/.gitconfig-personal`)
- `~/Artifacts/work/**` → work identity (`git/.gitconfig-work`)

Clone/create repos under the right one and the email/SSH key/URL rewrites
apply automatically. Verify with `git config user.email` from inside a repo.

## Uninstalling

Everything is a symlink into `~/.config/<tool>` (or `~/.tool` for the
handful that need it — `.zshrc`, `.tmux.conf`, `.gitconfig*`). To back out:

```sh
find ~ -maxdepth 3 -type l -lname "*/dotfiles-macos/*" -delete
# tmux.conf (both the ~/.tmux.conf and ~/.config/tmux/tmux.conf copies)
# point into the vendored oh-my-tmux clone, not this repo — catch those too:
find ~ -maxdepth 3 -type l -lname "*/oh-my-tmux/*" -delete
```

Then restore whatever `setup.sh` backed up from `~/.dotfiles-backup/`, and
`brew uninstall`/`brew uninstall --cask` anything you don't want to keep —
`setup.sh` never uninstalls packages on its own.
