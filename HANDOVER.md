# Handover — 2026-09-14

## Session summary

Three pieces of work this session, all following the existing per-tool
folder + `setup.sh` symlink/install pattern:

### 1. Orca + omp — "ADE" (Agent Development Environment) pairing

- **omp** (`can1357/tap/omp`) — terminal coding agent CLI, added to
  `setup.sh` FORMULAE next to Claude Code/opencode. **Installed.**
- **Orca** (`stablyai/orca/orca`) — desktop app that orchestrates Claude
  Code/opencode/omp in parallel across isolated git worktrees, added to
  `setup.sh` CASKS. **Installed.**
- Both new taps (`can1357/tap`, `stablyai/orca`) added to the tap list
  and the tap-trust list.
- README.md's tools table got two new rows for these.
- **Discovery:** this machine's Homebrew 7.0.1 eagerly validates every
  formula/cask in a tap at tap-time, so an *untrusted* tap fails
  validation and the whole `brew tap` call errors out and rolls back.
  Fix: `brew trust --tap <tap>` **before** `brew tap <tap>`, not after.
  `setup.sh` was reordered — trust step now runs before the tap step, for
  all five third-party taps in the repo, not just the two new ones.

### 2. omp `modelRoles` config

- Set via `omp config set modelRoles '{...}'`:
  `default`/`task` → `anthropic/claude-sonnet-5`, `smol`/`commit` →
  `anthropic/claude-haiku-4-5`, `slow`/`plan` →
  `anthropic/claude-opus-5:high`. Verified live with `omp config get
  modelRoles`.
- Captured the resulting `~/.omp/agent/config.yml` into the repo as
  `omp/config.yml`, then symlinked it back in place (`setup.sh`'s `link`
  helper backed up the pre-existing real file to
  `~/.dotfiles-backup/20260914-115437/` before linking).
- **Gotcha:** omp does NOT use an XDG config path by default, even though
  `$XDG_CONFIG_HOME` is set on this machine — it stays on the legacy
  `~/.omp/agent/config.yml` unless `omp config init-xdg` is explicitly
  run (which also relocates data/state/cache roots — deliberately not
  done here, out of scope for a model-roles change).

### 3. omp `providers.webSearchOrder`

- Set via `omp config set providers.webSearchOrder '["anthropic","duckduckgo","startpage","google"]'`.
  `anthropic` first because the user is already OAuth-authenticated for
  Claude (confirmed via `omp usage`) and has no other search-provider API
  keys configured (checked `~/.zshrc.local` and dotfiles `zsh/*.zsh` for
  EXA/TAVILY/BRAVE/KAGI/etc. — none set), so it's the only
  auth-gated provider that actually works without new signup; the rest
  are free/keyless scrape fallbacks for resilience.
- Reverse-engineered the full valid provider list from the `omp` binary
  itself (`strings` + grep for the `Nie`/`ym` arrays in
  `packages/coding-agent/src/web/search/provider.ts`), since neither
  `omp config list` nor `omp search --help` enumerate it: `auto`,
  `perplexity`, `gemini`, `anthropic`, `codex`, `xai`, `zai`, `exa`,
  `tinyfish`, `jina`, `kagi`, `tavily`, `firecrawl`, `brave`, `kimi`,
  `parallel`, `synthetic`, `searxng`, `startpage`, `duckduckgo`,
  `ecosia`, `google`, `mojeek`. Worth revisiting if the user later gets
  Gemini or OpenAI/Codex OAuth logins — those generally beat Claude's
  native web search on quality.
- Since `omp/config.yml` is a symlink (see below), setting this via the
  live `omp` CLI updated the committed repo file automatically — no
  manual copy step needed.

### 4. omp `cekat` provider (office LiteLLM gateway)

- Mirrors opencode's existing `cekat` provider (`opencode/opencode.json`)
  so omp can use the same office gateway and models.
- omp's custom-provider config lives in a *different* file than settings:
  `~/.omp/agent/models.yml` (schema documented in `docs/models.md` in the
  omp GitHub repo — not discoverable from `omp config list`/`--help`,
  had to fetch the doc directly). Added `omp/models.yml` to the repo,
  symlinked the same way as `omp/config.yml`.
- Listed all 14 models explicitly (same ids/names as
  `opencode/opencode.json`) rather than using omp's
  `discovery.type: litellm` auto-discovery — guarantees identical model
  ids/names between the two agents instead of depending on the gateway's
  own discovery metadata (which may format things differently).
- Reuses the same `$CEKAT_API_KEY` env var opencode already reads from
  `~/.zshrc.local` — no new secret needed. Updated
  `zsh/.zshrc.local.example`'s comment to mention both consumers.
- Verified end-to-end with a live call:
  `omp -p --model cekat/anthropic/claude-haiku-4.5 "say OK" --no-tools --no-session --max-time 30`
  → returned "OK", confirming auth actually works, not just that the
  provider registers.

### 5. helm + helm-diff (development-tools.sh)

- `helm` added to FORMULAE. **Installed.**
- `helm plugin install --verify=false https://github.com/databus23/helm-diff`
  step added (Helm 4 requires `--verify=false` for git-URL plugin
  installs since they can't be signature-verified — not a real security
  weakening, just how helm-diff is distributed).
- **Not yet installed** — this session's auto-mode classifier blocks any
  Bash command containing `--verify=false` outright, no matter who/why.
  **User needs to run this line themselves:**
  ```
  helm plugin install --verify=false https://github.com/databus23/helm-diff
  ```

## Repo structure notes (for a fresh session with no memory)

- `setup.sh` — base install (Homebrew, taps, general CLI + GUI apps/fonts,
  fonts, tap-trust for third-party casks/formulae). Has a known gotcha
  (see project memory `dotfiles_macos_project.md`) — check before editing.
- `development-tools.sh` — optional DevOps layer on top of setup.sh
  (kubectl, k9s, helm, terraform tooling, etc. + a separate GUI-apps
  CASKS array for dev tools like VS Code, Freelens, DBeaver). Idempotent,
  safe to re-run.
- `aerospace/aerospace.toml` — window manager config; app-launch shortcuts
  live under `alt-shift-<letter>` in the main binding mode.
- `omp/config.yml` — omp's settings (modelRoles etc.), symlinked to the
  legacy `~/.omp/agent/config.yml`, not an XDG path.
- `omp/models.yml` — omp's custom-provider config (the "cekat" office
  gateway), symlinked to `~/.omp/agent/models.yml`. Different file from
  `config.yml`, different schema — see `docs/models.md` upstream.

## Open items

- **helm-diff plugin still needs manual install** (see above — blocked
  for this session specifically, not a real blocker for the user).
- No aerospace launch shortcut was added for Orca; ask the user if they
  want one (pattern: `alt-shift-<letter>`, see Obsidian's `alt-shift-o`).
