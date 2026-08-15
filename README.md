# dotfiles-macos

A minimal, i3-style tiling workflow for macOS — without disabling SIP or
fighting the OS's window model. One folder per tool, a single install
script, and configs meant to be read and tweaked, not reverse-engineered.

Everything shares a restrained [Catppuccin Mocha](https://catppuccin.com)
palette, so the bar, window borders, terminal, and editor all read as one
system.

## Features

| Tool | What it does | Why it's here |
|---|---|---|
| [AeroSpace](https://github.com/nikitabobko/aerospace) | i3-style tiling window manager | Real tiling on macOS without touching native Spaces or disabling SIP |
| [JankyBorders](https://github.com/FelixKratz/JankyBorders) | Active/inactive window outlines | Makes it obvious at a glance which window is focused |
| [SketchyBar](https://github.com/FelixKratz/SketchyBar) | Status bar, configured in Lua | Live workspace indicator wired to AeroSpace's events, plus clock/battery/wifi/volume |
| [WezTerm](https://wezterm.org) | GPU-accelerated terminal | Fast, scriptable in Lua, tmux-style pane splitting built in |
| [tmux](https://github.com/gpakosz/.tmux) ("Oh my tmux!") | Terminal multiplexer | Sessions that survive an SSH drop or a WezTerm restart; same vim-style pane navigation as everywhere else |
| [Neovim](https://neovim.io) | Primary text editor | LSP, Treesitter, fuzzy finding — a lean lazy.nvim setup, not a distro |
| [Starship](https://starship.rs) | Shell prompt | Fast, minimal, easy to theme |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info on new shells | Quick at-a-glance host/CPU/memory summary, colored via the terminal's own theme |
| [yazi](https://yazi-rs.github.io) | Terminal file manager | Fast, vim-style navigation, image previews; `y` opens it and `cd`s your shell to wherever you navigated |
| [htop](https://htop.dev) / [btop](https://github.com/aristocratos/btop) | Process monitors | `htop` for the classic view, `btop` (aliased over `top`) for the fuller dashboard — kept both since they cover different moments |
| [Claude Code](https://claude.com/product/claude-code) | AI coding agent CLI | `claude` in any project directory |
| [opencode](https://opencode.ai) | AI coding agent CLI | `opencode`, an alternative agent with a different model/provider story |
| git + [delta](https://dandavison.github.io/delta) | Version control, syntax-highlighted diffs | Identity/SSH key auto-switches by directory — see below |
| zsh (no framework) | Shell | Organized, commented, no oh-my-zsh overhead — installed via Homebrew for a newer version than the one macOS ships |

## Repo structure

```
aerospace/     AeroSpace window manager config
borders/       JankyBorders window outline config
sketchybar/    SketchyBar status bar (Lua, via SbarLua)
wezterm/       WezTerm terminal config
tmux/          tmux.conf.local — customization layer for the vendored "Oh my tmux!"
nvim/          Neovim config (lazy.nvim)
fastfetch/     System info shown on new top-level shells
yazi/          Terminal file manager config
git/           .gitconfig, .gitconfig-personal, .gitconfig-work
zsh/           aliases.zsh, functions.zsh, completions.zsh, .zshrc.local.example
.zshrc         Shell entry point
starship.toml  Prompt config
setup.sh       Installs everything and symlinks configs into place
development-tools.sh  Optional DevOps toolchain (see below) — layered on top of setup.sh
```

Each tool's folder is self-contained — open it, and everything relevant to
that tool is inside.

## Install

```sh
git clone <this-repo-url> ~/dotfiles-macos
cd ~/dotfiles-macos
./setup.sh
```

`setup.sh`:
1. Installs Homebrew if it's missing.
2. Installs every formula/cask this repo needs (window management stack,
   WezTerm, Neovim, Starship, modern CLI tools, yazi, htop, fastfetch,
   Claude Code, opencode, a Nerd Font).
3. Builds [SbarLua](https://github.com/FelixKratz/SbarLua), the Lua API
   SketchyBar's config is written against, and vendors
   [Oh my tmux!](https://github.com/gpakosz/.tmux) into
   `~/.local/share/tmux/oh-my-tmux`.
4. Symlinks each folder into `~/.config/<tool>` (and `.zshrc`/
   `starship.toml` to their expected locations) — existing files in the
   way are backed up to `~/.dotfiles-backup/<timestamp>/`, never deleted.
5. Copies `zsh/.zshrc.local.example` to `~/.zshrc.local` on first run
   (git-ignored — put machine-specific overrides there).
6. Hides the native macOS menu bar (`defaults write NSGlobalDomain
   _HIHideMenuBar -bool true`, no SIP involved) so SketchyBar is the only
   bar on screen — log out/in if it's still visible afterwards.
7. Starts AeroSpace, Borders, and SketchyBar.

It's idempotent — re-run it any time after pulling changes.

## Optional: DevOps toolchain

```sh
./development-tools.sh
```

A separate, also-idempotent script (run `setup.sh` first) for a DevOps-flavored
toolchain that not everyone using this repo needs:

| Tool | What it does |
|---|---|
| [VS Code](https://code.visualstudio.com) | Editor, for the times a full IDE beats Neovim |
| [gvm](https://gvm.sh) | Go version manager — installed via its own installer (no Homebrew formula exists), `gvm install latest` to get Go itself |
| [OpenTofu](https://opentofu.org) / [Terragrunt](https://terragrunt.gruntwork.io) | Infrastructure as code |
| [Ansible](https://www.ansible.com) | Config management (`ansible-vault` ships as a subcommand) |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) / [kubectx](https://github.com/ahmetb/kubectx) | Kubernetes CLI + fast context/namespace switching (`kubectx`/`kubens`) |
| [Freelens](https://freelens.app) | Kubernetes IDE — open-source Lens fork |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal git UI |
| [jq](https://jqlang.org) / [yq](https://github.com/mikefarah/yq) | JSON / YAML processors |
| [Google Cloud CLI](https://cloud.google.com/cli) / [AWS CLI v2](https://aws.amazon.com/cli) | `gcloud`/`gsutil`/`bq` and `aws` |
| [Python](https://www.python.org) / [Node](https://nodejs.org) / [pnpm](https://pnpm.io) | Runtimes — `npm` ships with Node |

`kubectl`, `yq`, `tofu`, and `aws` completions are wired into
`zsh/completions.zsh` automatically once those binaries are on PATH — no
extra setup.

## git identity switching

`git/.gitconfig` uses `includeIf "gitdir:...` to load a different identity
and SSH key depending on which directory a repo lives under, no manual
`git config` per-repo needed:

| Directory | Identity file | Used for |
|---|---|---|
| `~/Artifacts/labs/` | `.gitconfig-personal` | Personal repos, pushes as `davidsugianto` |
| `~/Artifacts/work/` | `.gitconfig-work` | Work repos, rewrites `github.com/cekataiofficial/*` to SSH |

Both currently share the same email/SSH key (`~/.ssh/personal.david.sugianto.pem`)
— split `.gitconfig-work` once a separate work identity/key exists; it's a
plain `[user]`/`[core]` block, nothing else depends on it matching personal.

**Security note carried over from the original config**: `core.sshCommand`
in both identity files sets `StrictHostKeyChecking=no`, which skips SSH host
key verification (accepts any host key without prompting or checking
`known_hosts`). That's weaker than the default and was already the case
before this repo — tighten it if you'd rather have the prompt back.

## Keybindings at a glance

AeroSpace uses `alt` as the primary modifier (vim-style `hjkl` for focus,
`alt+shift+hjkl` to move windows, `alt+1..9` for workspaces). WezTerm
leaves `alt` alone and uses `ctrl+a` as a leader for pane splits/navigation,
plus `cmd+1..9` for tabs. tmux keeps its default `ctrl+b` prefix (not
`ctrl+a`) precisely so it doesn't collide with WezTerm's leader when you run
tmux inside it. See `aerospace/aerospace.toml`, `wezterm/config/keys.lua`,
and `tmux/tmux.conf.local` — all commented inline.

## Customizing

- **Colors**: `sketchybar/colors.lua`, `borders/bordersrc`,
  `wezterm/config/appearance.lua`, `tmux/tmux.conf.local`, and
  `nvim/lua/plugins/colorscheme.lua` all use Catppuccin Mocha — swap the
  flavour/hex values in one place at a time, or add a shared palette file
  if you outgrow copy-paste. `fastfetch/config.jsonc` and `yazi/yazi.toml`
  don't hardcode colors at all — they inherit whatever WezTerm's ANSI
  palette is, so they follow automatically.
- **Per-app window rules**: `aerospace/aerospace.toml`, under
  `[[on-window-detected]]`.
- **Bar items**: `sketchybar/items/` — one file per item, `items/init.lua`
  controls load/render order.
- **Neovim plugins**: `nvim/lua/plugins/` — one file per plugin or concern,
  auto-loaded by lazy.nvim.

## Operations

Reload commands, updating, vendored-dependency refresh, known gotchas,
backups, and uninstalling all live in [OPERATIONS.md](OPERATIONS.md).
