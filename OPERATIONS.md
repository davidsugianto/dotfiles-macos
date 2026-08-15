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
