# dotfiles-macos

A minimal, i3-style tiling workflow for macOS, without disabling SIP. One
folder per tool, one install script, and configs meant to be read and tweaked.
Everything shares the [Catppuccin Mocha](https://catppuccin.com) palette, so
the bar, borders, terminal and editor read as one system.

## What's inside

| Tool | Role |
|---|---|
| [AeroSpace](https://github.com/nikitabobko/aerospace) | i3-style tiling window manager (no SIP changes, native Spaces untouched) |
| [JankyBorders](https://github.com/FelixKratz/JankyBorders) | Active/inactive window outlines |
| [SketchyBar](https://github.com/FelixKratz/SketchyBar) | Status bar in Lua, synced with AeroSpace workspaces |
| [WezTerm](https://wezterm.org) | GPU terminal, Lua config, built-in pane splits |
| [tmux](https://github.com/gpakosz/.tmux) | Multiplexer ("Oh my tmux!" plus a local override layer) |
| [Neovim](https://neovim.io) | Editor on lazy.nvim, with LSP/format/lint for Lua, Bash, C/C++, Go, TS/JS, Python, YAML, JSON, Terraform |
| [Starship](https://starship.rs) / zsh | Prompt and framework-free shell |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch), [yazi](https://yazi-rs.github.io), [htop](https://htop.dev), [btop](https://github.com/aristocratos/btop) | System info, file manager, process monitors |
| git + [delta](https://dandavison.github.io/delta) | Identity and SSH key switch by directory ([details](docs/devops.md)) |
| [Obsidian](https://obsidian.md) | Notes (`alt+shift+o`) |
| Claude Code, opencode, omp, pi, [Orca](https://www.onorca.dev), [Herdr](https://herdr.dev) | AI coding agents, workflow, model roles and MCP servers ([details](docs/agents.md)) |

## Install

A fresh Mac needs Xcode's Command Line Tools first (a GUI dialog, no silent
flag). If `xcode-select -p` prints a path, skip this.

```sh
xcode-select --install
git clone <this-repo-url> ~/dotfiles-macos
cd ~/dotfiles-macos
./setup.sh
```

`setup.sh` is idempotent, so re-run it after pulling changes. It:

1. Installs Homebrew if missing, then every formula and cask this repo needs.
2. Builds [SbarLua](https://github.com/FelixKratz/SbarLua) and vendors Oh my tmux! into `~/.local/share/tmux/oh-my-tmux`.
3. Symlinks each folder into `~/.config/<tool>`. The agents are the exception, since they don't use XDG paths: omp links into `~/.omp/agent/`, pi into `~/.pi/agent/`, Claude Code into `~/.claude/`. Existing files are backed up to `~/.dotfiles-backup/<timestamp>/`, never deleted.
4. Installs the omp and pi plugins, extensions and themes, plus Node.js and Browser Relay. See [docs/agents.md](docs/agents.md).
5. Copies `zsh/.zshrc.local.example` to `~/.zshrc.local` on first run. It is git-ignored, so put machine-specific overrides and secrets there.
6. Hides the native menu bar (no SIP involved; log out and in if it's still visible), then starts AeroSpace, Borders and SketchyBar.

Optional DevOps toolchain (kubectl, helm, OpenTofu, gcloud, aws and more):

```sh
./development-tools.sh   # run setup.sh first
```

Neovim's Go, Node/TS/JS, Python and Terraform support needs this script's
`go`, `node` and `python`. Without them only those language servers fail to
install in Mason. See [docs/devops.md](docs/devops.md).

## Repo layout

```
aerospace/ borders/ sketchybar/   window manager, window outlines, status bar
wezterm/ tmux/ nvim/              terminal, multiplexer, editor
fastfetch/ yazi/ k9s/ sofka/      system info, file manager, Kubernetes TUIs
git/ zsh/ .zshrc starship.toml    git identities, shell, prompt
claude/ omp/ pi/ opencode/        AI agent configs
agent/ herdr/ herdr-app/ rtk/     shared agent skills, Herdr, rtk hooks
docs/                             guides (see below)
setup.sh                          install and symlink everything
development-tools.sh              optional DevOps toolchain
```

Each folder is self-contained: everything for a tool lives inside it.

## Keybindings

- **AeroSpace**: `alt` is the modifier. `hjkl` moves focus, `alt+shift+hjkl` moves windows, `alt+1..9` switches workspace.
- **WezTerm**: `ctrl+a` is the leader for pane splits and navigation, `cmd+1..9` switches tabs.
- **tmux**: keeps `ctrl+b`, so it doesn't collide with WezTerm's leader when nested.

Sources are commented inline: `aerospace/aerospace.toml`, `wezterm/config/keys.lua`, `tmux/tmux.conf.local`.

## Customizing

- **Colors**: Catppuccin Mocha is set in `sketchybar/colors.lua`, `borders/bordersrc`, `wezterm/config/appearance.lua`, `tmux/tmux.conf.local` and `nvim/lua/plugins/colorscheme.lua`. `fastfetch` and `yazi` inherit WezTerm's ANSI palette.
- **Window rules**: `aerospace/aerospace.toml`, under `[[on-window-detected]]`.
- **Bar items**: `sketchybar/items/`, one file per item. `items/init.lua` sets the load order.
- **Neovim**: `nvim/lua/plugins/`, one file per plugin, auto-loaded. Add LSP servers in `lsp.lua` (`ensure_installed`), formatters in `formatting.lua` (`formatters_by_ft`), linters in `linting.lua` (`linters_by_ft`).

## More docs

| Doc | Covers |
|---|---|
| [OPERATIONS.md](OPERATIONS.md) | Reloading, updating, vendored dependencies, known gotchas, backups, uninstalling |
| [docs/agents.md](docs/agents.md) | Claude Code, opencode, omp, pi: model roles, rtk, Herdr superagent, Browser Relay, Orca |
| [docs/mcp.md](docs/mcp.md) | Datadog, Jira, Slack and Cloudflare MCP servers: setup and login |
| [docs/devops.md](docs/devops.md) | DevOps toolchain, git identity and AWS profile switching |
| [docs/claude-workflow-guide.md](docs/claude-workflow-guide.md), [pi](docs/pi-workflow-guide.md), [omp](docs/omp-workflow-guide.md) | Step-by-step workflow guides |
| [docs/model-profiles.md](docs/model-profiles.md), [docs/pi-prompts.md](docs/pi-prompts.md) | Model profiles and annotated prompts |
| [docs/example-skills-cmd.md](docs/example-skills-cmd.md), [docs/prompt-skills.md](docs/prompt-skills.md) | How to invoke skills; the `prompt-forge` and `prompt-openbot` skills (rough text to a prompt, and a prompt to a command that runs an openbot-agent-kit agent) |
