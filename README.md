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
| [Neovim](https://neovim.io) | Primary text editor | Full IDE layout (file tree, tab bar, breadcrumbs) with LSP/format/lint for Lua, Bash, C/C++, Go, Node/TS/JS, Python, YAML, JSON, and Terraform — hand-assembled via lazy.nvim, not a pre-packaged distro |
| [Starship](https://starship.rs) | Shell prompt | Fast, minimal, easy to theme |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info on new shells | Quick at-a-glance host/CPU/memory summary, colored via the terminal's own theme |
| [yazi](https://yazi-rs.github.io) | Terminal file manager | Fast, vim-style navigation, image previews; `y` opens it and `cd`s your shell to wherever you navigated |
| [htop](https://htop.dev) / [btop](https://github.com/aristocratos/btop) | Process monitors | `htop` for the classic view, `btop` (aliased over `top`) for the fuller dashboard — kept both since they cover different moments |
| [Claude Code](https://claude.com/product/claude-code) | AI coding agent CLI | `claude` in any project directory |
| [opencode](https://opencode.ai) | AI coding agent CLI | `opencode`, an alternative agent with a different model/provider story; themed Catppuccin Mocha (transparent), matching WezTerm/Neovim/k9s (`opencode/`); also configured with a custom "cekat" provider (office LLM gateway) — its API key is read from `$CEKAT_API_KEY`, set in the git-ignored `~/.zshrc.local`, never committed |
| [omp](https://omp.sh) | AI coding agent CLI | Another alternative agent (`omp`, aka "Oh My Pi") — subagents, plan mode, LSP/DAP wired in; installed via `can1357/tap/omp`; per-role model config (`omp/`) picks Sonnet 5 by default, Haiku 4.5 for smol/commit tasks, Opus 5 (high) for slow/plan; themed Catppuccin (transparent status line), matching WezTerm/Neovim/k9s/opencode; web search tries Anthropic's native tool first (already authenticated, no extra key), then free keyless fallbacks (duckduckgo, startpage, google); also configured with the same custom "cekat" provider (office LiteLLM gateway) as opencode — `omp/models.yml`, same `$CEKAT_API_KEY` env var; [omp-model-profiles](https://github.com/rezhajulio/omp-model-profiles) plugin (installed via `omp plugin install`, needs `bun`) adds `/profile personal-labs` (the Anthropic roles above) and `/profile work-cekataiofficial` (internal GPT-5.6 Sol/Terra/Luna via the cekat gateway — Sol for slow/plan, Terra for default/task, Luna for smol/commit) to switch the whole role set in-session — `omp/model-profiles/` |
| [pi](https://pi.dev) | AI coding agent CLI | The minimal upstream agent `omp`/"Oh My Pi" builds on; installed via `brew install pi-coding-agent`; task-based model routing across the same default/smol/slow/plan/commit/task/web split as `omp/`, via the [pi-model-roles](https://github.com/spksoft/pi-model-roles) extension (`pi/model-roles/`, deployed with `pi-roles personal\|work`, not symlinked — see below); instant `/profile <name>` switching via [pi-profile](https://github.com/Eddie0521/pi-profile) (`pi/profiles/`, one profile per role plus `personal-labs`/`work-cekataiofficial`); Catppuccin Mocha Mauve by default plus eight vendored switchable themes from [pi-extensions](https://github.com/luongnv89/pi-extensions) (`pi/themes/`); also configured with the same custom "cekat" provider as opencode/omp — `pi/models.json`, same `$CEKAT_API_KEY` env var |
| [Orca](https://www.onorca.dev) | Agent Development Environment (ADE) | Desktop app for running Claude Code/opencode/omp in parallel, each in its own isolated git worktree, with diffs viewable side by side; installed via `stablyai/orca/orca`; launch shortcut `alt+shift+r` (see [aerospace/aerospace.toml](aerospace/aerospace.toml)); default tab agent set to `omp` so new tabs use the internal "cekat" LLM gateway by default, personal Claude Code still one command away — see below |
| git + [delta](https://dandavison.github.io/delta) | Version control, syntax-highlighted diffs | Identity/SSH key auto-switches by directory — see below |
| zsh (no framework) | Shell | Organized, commented, no oh-my-zsh overhead — installed via Homebrew for a newer version than the one macOS ships |
| [Obsidian](https://obsidian.md) | Knowledge base / notes | Local-first Markdown notes; launch shortcut `alt+shift+o` (see [aerospace/aerospace.toml](aerospace/aerospace.toml)) |

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
k9s/           k9s config.yaml + Catppuccin Mocha (transparent) skin
opencode/      tui.json + Catppuccin Mocha (transparent) theme + opencode.json (custom provider)
omp/           config.yml (modelRoles, webSearchOrder) + models.yml (custom "cekat" provider) + mcp.json (Datadog MCP server) + model-profiles/*.yml (personal-labs, work-cekataiofficial), linked to ~/.omp/agent/ and ~/.omp/model-profiles/
pi/            settings.json + models.json (custom "cekat" provider) + mcp.json (Datadog MCP server, via pi-mcp-adapter) + themes/*.json (switchable Pi themes) + model-roles/*.yaml (personal-labs, work-cekataiofficial) + profiles/*.json + extensions/subagents-pi/ (vendored, not on npm), linked to ~/.pi/agent/ and ~/.pi/profiles/
git/           .gitconfig, .gitconfig-personal, .gitconfig-work
zsh/           aliases.zsh, functions.zsh, completions.zsh, .zshrc.local.example
.zshrc         Shell entry point
starship.toml  Prompt config
setup.sh       Installs everything and symlinks configs into place
development-tools.sh  Optional DevOps toolchain (see below) — layered on top of setup.sh
```

Each tool's folder is self-contained — open it, and everything relevant to
that tool is inside.

## Prerequisites

A completely fresh Mac has neither `git` nor a compiler — both come from
Xcode's Command Line Tools, which `git clone` below needs first:

```sh
xcode-select --install
```

This pops a GUI installer dialog — click through it (there's no silent
flag). Already installed? `xcode-select -p` prints a path instead of
erroring, so you can skip straight to Install.

[Homebrew](https://brew.sh) is the only other thing this setup depends on,
but there's no separate step for it — `setup.sh` checks for it and installs
it automatically (`brew` already on PATH? it just skips ahead). Install it
yourself first only if you'd rather review
[Homebrew's install script](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
before running it, or already manage it separately:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

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
   Claude Code, opencode, omp, pi, bun, Orca, a Nerd Font).
3. Builds [SbarLua](https://github.com/FelixKratz/SbarLua), the Lua API
   SketchyBar's config is written against, and vendors
   [Oh my tmux!](https://github.com/gpakosz/.tmux) into
   `~/.local/share/tmux/oh-my-tmux`.
4. Symlinks each folder into `~/.config/<tool>` (`.zshrc`/`starship.toml`
   to their expected locations; `omp/config.yml`+`omp/models.yml`+
   `omp/mcp.json` to `~/.omp/agent/` and
   `pi/settings.json`+`pi/models.json`+`pi/mcp.json` to
   `~/.pi/agent/`, since neither agent uses an XDG config path; and
   `omp/model-profiles/`+`pi/profiles/` to `~/.omp/model-profiles/`+
   `~/.pi/profiles/`) — existing files in the way are backed up to
   `~/.dotfiles-backup/<timestamp>/`, never deleted.
5. Installs the [omp-model-profiles](https://github.com/rezhajulio/omp-model-profiles)
   plugin via `omp plugin install` (needs `bun`, tapped/installed in step 2)
 +
   so `/profile personal-labs` and `/profile work-cekataiofficial` are
   available inside omp.
6. Installs pi's [pi-model-roles](https://github.com/spksoft/pi-model-roles),
   [pi-profile](https://github.com/Eddie0521/pi-profile),
   [Catppuccin](https://github.com/XYenon/catppuccin-pi-coding-agent), and the
   eight vendored switchable themes in `pi/themes/` from
   [pi-extensions](https://github.com/luongnv89/pi-extensions),
   [statusline-pi/timestamp-pi](https://github.com/luongnv89/pi-extensions),
   [pi-subagents](https://github.com/tintinweb/pi-subagents), and
   [pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) packages
   via `pi install`, plus the vendored `pi/extensions/subagents-pi/` fleet
   panel from a local path, then deploys the personal-labs model-roles config
   (see "pi model-role switching", "pi status & subagent extensions", and
   "Datadog MCP" below).
7. Copies `zsh/.zshrc.local.example` to `~/.zshrc.local` on first run
   (git-ignored — put machine-specific overrides there).
8. Hides the native macOS menu bar (`defaults write NSGlobalDomain
   _HIHideMenuBar -bool true`, no SIP involved) so SketchyBar is the only
   bar on screen — log out/in if it's still visible afterwards.
9. Starts AeroSpace, Borders, and SketchyBar.

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
| [OpenTofu](https://opentofu.org) / [Terragrunt](https://terragrunt.gruntwork.io) | Infrastructure as code — used deliberately instead of HashiCorp's `terraform` CLI (BSL license); Neovim's Terraform formatter is wired to `tofu fmt` for the same reason |
| [Ansible](https://www.ansible.com) | Config management (`ansible-vault` ships as a subcommand) |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) / [kubectx](https://github.com/ahmetb/kubectx) | Kubernetes CLI + fast context/namespace switching (`kubectx`/`kubens`) |
| [k9s](https://k9scli.io) | Terminal Kubernetes UI — themed Catppuccin Mocha (transparent), matching WezTerm/Neovim (`k9s/`) |
| [sofka](https://sofka.rs) | Kubernetes TUI (Rust, k9s-inspired) — Flux/Argo CD built in, native incident view, themed Catppuccin Mocha, matching WezTerm/Neovim/k9s (`sofka/`); `Ctrl-T` opens a WezTerm pane with `kubectl`/`helm` pinned to Sofka’s active context and namespace, including from tmux sessions with stale WezTerm socket state |
| [Helm](https://helm.sh) + [helm-diff](https://github.com/databus23/helm-diff) | Kubernetes package manager + `helm diff upgrade`/`helm diff rollback` plugin (previews changes before applying) |
| [Freelens](https://freelens.app) | Kubernetes IDE — open-source Lens fork |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal git UI |
| [jq](https://jqlang.org) / [yq](https://github.com/mikefarah/yq) | JSON / YAML processors |
| [Google Cloud CLI](https://cloud.google.com/cli) / [AWS CLI v2](https://aws.amazon.com/cli) | `gcloud`/`gsutil`/`bq` and `aws` — `gke-gcloud-auth-plugin` is installed alongside gcloud (`kubectl` needs it to auth against GKE clusters); AWS has two SSO profiles (`cekataiofficial`/`personal`) that auto-switch by directory, same pattern as git identity — see below |
| [Python](https://www.python.org) / [Node](https://nodejs.org) / [pnpm](https://pnpm.io) | Runtimes — `npm` ships with Node |
| [HTTPie](https://httpie.io) | `http`/`https` CLI (friendlier curl) plus the [HTTPie for Desktop](https://httpie.io/product) GUI companion |
| [Apidog](https://apidog.com) | API development platform — design, mock, test, and document APIs in one GUI app |

`kubectl`, `yq`, `tofu`, and `aws` completions are wired into
`zsh/completions.zsh` automatically once those binaries are on PATH — no
extra setup.

**Neovim's language coverage needs this script too.** `setup.sh` alone gets
you LSP/format/lint for Lua, Bash, and C/C++. Go, Node/TS/JS, Python, and
Terraform additionally need `go` (via `gvm install latest`, above), `node`,
and `python` on PATH before Neovim can install their language servers —
without them, Mason logs a failed install for just those servers (`:Mason`
or `:MasonLog` to check) and everything else keeps working.

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

## AWS profile switching

`zsh/functions.zsh` sets `AWS_PROFILE` automatically based on directory, via
a `chpwd` hook — same directory split as git identity above:

| Directory | AWS profile | Used for |
|---|---|---|
| `~/Artifacts/work/cekataiofficial/` | `cekataiofficial` | Work AWS account |
| `~/Artifacts/labs/` | `personal` | Personal AWS account |

Outside both trees `AWS_PROFILE` is unset rather than left stale, so `aws`
commands fail closed instead of silently hitting the wrong account. Both
profiles authenticate via AWS SSO (IAM Identity Center) — set up once per
machine with `aws configure sso --profile cekataiofficial` and
`aws configure sso --profile personal` (interactive; not part of `setup.sh`
since it needs a browser login), then re-auth per session with
`aws sso login --profile <name>` when the cached SSO token expires.

## pi model-role switching

`pi/` mirrors `omp/`'s modelRoles concept using two vanilla-`pi` extensions,
since `pi` itself has no built-in role system:

| Mechanism | Extension | What it does |
|---|---|---|
| Automatic task routing | [pi-model-roles](https://github.com/spksoft/pi-model-roles) | Classifies each submitted task and auto-picks its model/effort from `~/.pi/agent/extensions/pi-model-roles/config.yaml` — the `default`/`smol`/`slow`/`plan`/`commit`/`task`/`web` split, same tiering as `omp/config.yml` |
| Manual identity switch | [pi-profile](https://github.com/Eddie0521/pi-profile) | `/profile <name>` inside pi — one profile per role (`pi/profiles/`) plus `personal-labs`/`work-cekataiofficial` account switches |

Swapping the whole personal/work role set (the `pi-model-roles` equivalent
of omp's `/profile personal-labs` / `/profile work-cekataiofficial`) needs a
shell command, not a slash command: `pi-model-roles` refuses to save through
a symlinked `config.yaml`, so `pi/model-roles/*.yaml` are copied into place
rather than linked.

```sh
pi-roles personal   # Anthropic direct — the global default
pi-roles work        # cekat gateway (office GPT-5.6 Luna/Terra/Sol)
```

Run `/reload` in every open `pi` session afterwards — `pi-model-roles` has
no file watcher. `pi-roles` is a plain script (`pi/scripts/pi-roles`,
linked to `~/.local/bin/pi-roles`), so `git diff` in this repo always shows
exactly which role set is checked in as the machine default.

## Cekat model tool-call routing

The Cekat LiteLLM gateway rejects function-tool requests for `azure_ai/gpt-6-luna`
and `azure_ai/gpt-6-sol` on `/v1/chat/completions`: LiteLLM attaches a
server-side `reasoning_effort` value, even when the client omits it. Setting
`compat.supportsReasoningEffort: false` or sending `reasoning_effort: "none"`
does not avoid this gateway behavior. Route these two models through the
Responses API instead by setting `api: openai-responses` on their model entries
in both `pi/models.json` and `omp/models.yml`. Keep the provider default as
`openai-completions` for the other models.

The pi model catalog reloads when `/model` is opened; use `/reload` in open
sessions if needed. After changing pi model-role sets with `pi-roles work` or
`pi-roles personal`, run `/reload` in each open session to load the copied role
config.

## pi status & subagent extensions

All from [luongnv89/pi-extensions](https://github.com/luongnv89/pi-extensions)
(MIT):

| Extension | What you get | Source |
|---|---|---|
| [statusline-pi](https://github.com/luongnv89/pi-extensions/tree/main/extensions/statusline-pi) | Footer: git branch/changed files, PR number, session cost, CPU/MEM, context tokens/%, tok/s, model | npm |
| [timestamp-pi](https://github.com/luongnv89/pi-extensions/tree/main/extensions/timestamp-pi) | Timestamp under every message + a prompt-cache TTL countdown in the footer | npm |
| [@tintinweb/pi-subagents](https://github.com/tintinweb/pi-subagents) | Orchestration engine — spawning, FleetView, the `Agent` tool | npm |
| [subagents-pi](pi/extensions/subagents-pi) | Fleet metrics panel (context, TPS, model, thinking) per managed subagent — companion to the extension above | **vendored**, not on npm |

`subagents-pi` isn't published to npm (confirmed against the npm registry,
not just its own README, which briefly claimed otherwise) — its own
install instructions are a local path into a clone of its monorepo. That
doesn't survive `setup.sh`'s idempotent re-runs on its own, so the exact
upstream `extensions/subagents-pi/` directory is vendored straight into
this repo (`pi/extensions/subagents-pi/`, byte-identical to upstream) and
installed as a local package: `pi install <path>`. Pi stores that as a
path relative to `~/.pi/agent` (not to this repo's `pi/` directory, even
though `settings.json` is symlinked there) — portable as long as
`setup.sh` (which recomputes it) runs on every machine, not just a
`git pull`. Re-sync the vendored copy by hand if upstream changes; nothing
here pulls updates automatically.

Toggle commands once installed: `/statusline-pi`, `/statusline-refresh`,
`/timestamp-pi`, `/subagents-pi`, `/subagents-pi-refresh`.

## Datadog MCP

omp and pi both talk to Datadog's hosted
[MCP server](https://docs.datadoghq.com/mcp_server/setup/) (logs, metrics,
traces, monitors, incidents, dashboards) over Streamable HTTP, defined as a
`datadog` server in `omp/mcp.json` (→ `~/.omp/agent/mcp.json`, native omp
MCP) and `pi/mcp.json` (→ `~/.pi/agent/mcp.json`, read by the
[pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) package —
pi has no built-in MCP). Two files because each agent has its own loader;
keep the server entries identical.

Auth is browser OAuth — the same Datadog login you use in the web app
(e.g. Google SSO); no API/application keys. Datadog supports dynamic client
registration and accepts omp's/pi's localhost callbacks, so no org
allow-listing is needed. Tokens are stored per agent (omp: its `agent.db`;
pi: the macOS keychain), never in this repo, and refresh automatically.

The endpoint is pinned to the org's site, US5
(`https://mcp.us5.datadoghq.com/api/unstable/mcp-server/mcp`, login at
`us5.datadoghq.com`), directly in both files — not via an env var, so omp/pi
launched from anywhere (Orca, an old shell) always hit the right site. For
another site swap the host (`mcp.datadoghq.com` = US1, `mcp.us3.datadoghq.com`,
`mcp.datadoghq.eu`, `mcp.ap1.datadoghq.com`, …) in both files and re-login.

First login, once per agent:

- omp: `/mcp reauth datadog` → browser opens → sign in → `/mcp test datadog`.
- pi: `/mcp-auth datadog` (or `/mcp`, Enter on the server) → browser → sign in.
  Servers connect lazily on first tool call — the agent finds tools via
  `mcp({ search: "logs" })`.

Default toolsets only; to add product toolsets append e.g.
`?toolsets=apm,llmobs` (or `all`) to the `url` in both files. If your org
signs in through a custom subdomain, append `?subdomain=<name>` too.

## Orca agent defaults

Orca has no config file of its own to track in this repo — all its settings
live in one Electron app-state blob
(`~/Library/Application Support/orca/profiles/local-default/orca-data.json`)
that also holds live session/account state, so it's deliberately **not**
symlinked here (unlike `omp/`/`opencode/`). Orca just spawns whichever CLI
you point it at, so "multiple models" comes for free from those CLIs' own
provider config:

- `settings.defaultTuiAgent` is set to `omp`, so a new Orca tab opens omp by
  default — which already has the "cekat" office LLM gateway wired in
  (`omp/models.yml`, same as `opencode/opencode.json`).
- Personal Claude Code is still available any time, just not the default:
  `orca terminal create --worktree active --command "claude"`, or pick
  Claude from Orca's agent picker.

If Orca is reinstalled or its app data is reset, redo this by hand (with
the Orca app quit first): flip `settings.defaultTuiAgent` from `"claude"`
to `"omp"` in the file above.

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
  auto-loaded by lazy.nvim. New LSP server → `plugins/lsp.lua`'s
  `ensure_installed`; new formatter → `plugins/formatting.lua`'s
  `formatters_by_ft`; new linter → `plugins/linting.lua`'s `linters_by_ft`.

## Operations

Reload commands, updating, vendored-dependency refresh, known gotchas,
backups, and uninstalling all live in [OPERATIONS.md](OPERATIONS.md).
