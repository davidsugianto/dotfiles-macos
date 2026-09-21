# Handover — 2026-09-14

## Session summary

Set up Orca + omp as an "ADE" (Agent Development Environment) pairing
alongside the existing Claude Code/opencode agents, then wired omp's
config to match this repo's existing opencode conventions. All following
the existing per-tool folder + `setup.sh` symlink/install pattern.
Committed in `cbd8bbd` ("feat(agent): setup omp"), except the gitignore
fix noted last below, which is still uncommitted.

### 1. Orca + omp installed

- **omp** (`can1357/tap/omp`) — terminal coding agent CLI, added to
  `setup.sh` FORMULAE next to Claude Code/opencode. **Installed.**
- **Orca** (`stablyai/orca/orca`) — desktop app that orchestrates Claude
  Code/opencode/omp in parallel across isolated git worktrees, added to
  `setup.sh` CASKS. **Installed.**
- Both new taps (`can1357/tap`, `stablyai/orca`) added to the tap list
  and the tap-trust list.
- **Discovery:** this machine's Homebrew 7.0.1 eagerly validates every
  formula/cask in a tap at tap-time, so an *untrusted* tap fails
  validation and the whole `brew tap` call errors out and rolls back.
  Fix: `brew trust --tap <tap>` **before** `brew tap <tap>`, not after.
  `setup.sh` was reordered — trust step now runs before the tap step, for
  all five third-party taps in the repo, not just the two new ones.

### 2. omp settings (`omp/config.yml` → `~/.omp/agent/config.yml`)

- `modelRoles`: `default`/`task` → `anthropic/claude-sonnet-5`,
  `smol`/`commit` → `anthropic/claude-haiku-4-5`, `slow`/`plan` →
  `anthropic/claude-opus-5:high`.
- `providers.webSearchOrder`: `["anthropic","duckduckgo","startpage","google"]`
  — `anthropic` first since the user is already OAuth-authenticated for
  Claude and has no other search-provider API keys configured; the rest
  are free/keyless scrape fallbacks. Revisit if Gemini/OpenAI OAuth
  logins are added later (`gemini`/`codex` generally beat Claude's
  native web search).
- **Gotcha:** omp does NOT use an XDG config path by default, even though
  `$XDG_CONFIG_HOME` is set on this machine — it stays on the legacy
  `~/.omp/agent/config.yml` unless `omp config init-xdg` is explicitly
  run (which also relocates data/state/cache roots — deliberately not
  done).

### 3. omp `cekat` provider (`omp/models.yml` → `~/.omp/agent/models.yml`)

- Mirrors opencode's existing `cekat` provider (`opencode/opencode.json`)
  — same office LiteLLM gateway, same `$CEKAT_API_KEY` env var (from
  `~/.zshrc.local`, updated its example comment to mention both
  consumers), same 14 models/ids listed explicitly rather than relying
  on omp's `discovery.type: litellm` auto-discovery.
- omp's custom-provider config is a *separate* file from settings
  (`models.yml`, not `config.yml`) — schema is documented in
  `docs/models.md` in the omp GitHub repo, not discoverable from
  `omp config list`/`--help`.
- Verified end-to-end with a live call:
  `omp -p --model cekat/anthropic/claude-haiku-4.5 "say OK" --no-tools --no-session --max-time 30`
  → returned "OK".

### 4. helm + helm-diff (`development-tools.sh`)

- `helm` added to FORMULAE. **Installed.**
- `helm plugin install --verify=false https://github.com/databus23/helm-diff`
  step added (Helm 4 requires `--verify=false` for git-URL plugin
  installs since they can't be signature-verified — not a real security
  weakening, just how helm-diff is distributed).
- **Still not installed** — blocked every time by this session's
  auto-mode security classifier, regardless of who/why. **Needs to be
  run manually, outside this session:**
  ```
  helm plugin install --verify=false https://github.com/databus23/helm-diff
  ```

### 5. Cleanup: stray `omp/config.yml.lock` (uncommitted)

- omp resolves the `config.yml` symlink and writes its runtime lock file
  (`config.yml.lock`, always empty) next to the *real* file — which is
  inside this repo, not `~/.omp/agent/` — so it got committed by
  accident in `cbd8bbd`.
- Fixed: `git rm --cached omp/config.yml.lock` + added `omp/*.lock` to
  `.gitignore`. **This fix itself is not yet committed** — do that
  before/with the next commit.

## Repo structure notes (for a fresh session with no memory)

- `setup.sh` — base install (Homebrew, taps, general CLI + GUI apps/fonts,
  fonts, tap-trust for third-party casks/formulae). Has a known gotcha
  (see project memory `dotfiles_macos_project.md`) — check before editing.
- `development-tools.sh` — optional DevOps layer on top of setup.sh
  (kubectl, k9s, sofka, helm, terraform tooling, etc. + a separate GUI-apps
  CASKS array for dev tools like VS Code, Freelens, DBeaver). Idempotent,
  safe to re-run.
- `aerospace/aerospace.toml` — window manager config; app-launch shortcuts
  live under `alt-shift-<letter>` in the main binding mode.
- `omp/config.yml` — omp's settings (modelRoles, webSearchOrder, etc.),
  symlinked to the legacy `~/.omp/agent/config.yml`, not an XDG path.
- `omp/models.yml` — omp's custom-provider config (the "cekat" office
  gateway), symlinked to `~/.omp/agent/models.yml`. Different file from
  `config.yml`, different schema — see `docs/models.md` upstream.

## Open items

- **helm-diff plugin still needs manual install** (see #4 above —
  blocked for this session specifically, not a real blocker for the
  user).
- **The `.gitignore`/lock-file fix in #5 is uncommitted** — fold it into
  the next commit.
- No aerospace launch shortcut was added for Orca; ask the user if they
  want one (pattern: `alt-shift-<letter>`, see Obsidian's `alt-shift-o`).
