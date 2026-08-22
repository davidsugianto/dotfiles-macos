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
  is even with `origin/main` through commit `1a481ce` (kubectl aliases +
  the `zsh/completions.zsh` fix below) — that part is pushed.
- **Working tree is NOT clean** — there's a chunk of finished, verified work
  sitting uncommitted because the user hasn't asked for a commit yet. Don't
  discard it; don't commit it either unless asked. `git status --short`:
  ```
   M .zshrc
   M README.md
   M development-tools.sh
   M setup.sh
   M zsh/.zshrc.local.example
  ?? k9s/
  ?? opencode/
  ```
- **What that uncommitted work is** (all validated live on this machine
  before being called done — see below, not just written and assumed
  correct):
  - `k9s/config.yaml` + `k9s/skins/catppuccin-mocha-transparent.yaml` —
    k9s themed Catppuccin Mocha, transparent (vendored from
    [catppuccin/k9s](https://github.com/catppuccin/k9s)'s
    `-transparent` variant, which uses `bgColor: default` throughout to let
    the terminal's own background/blur show through, same effect as
    WezTerm's opacity/blur settings). `setup.sh` symlinks `config.yaml` and
    `skins/` individually into `~/.config/k9s`, **not the whole directory**
    — an integrity audit after the fact caught k9s writing its own
    auto-generated `aliases.yaml` straight into the git-tracked repo when
    the whole dir was symlinked (silent, no error; only surfaced by
    `git status` showing an untracked file appear on its own after just
    launching k9s to test it). Same reasoning as opencode below — don't
    symlink a tool's whole config dir if it writes runtime state into it.
  - `opencode/tui.json` + `opencode/themes/catppuccin-mocha.json` — opencode
    themed Catppuccin Mocha, transparent (hand-built from
    [catppuccin/opencode](https://github.com/catppuccin/opencode)'s mauve
    theme, with `background`/`backgroundPanel`/`backgroundElement`/
    `diffContextBg` set to `"none"`, opencode's equivalent of k9s's
    `default`). **Known upstream limitation, not a bug in this config**: 1-2
    minor UI elements still paint a small hardcoded backdrop
    (`#2f3138`/`#33363d`, not from this theme) instead of inheriting
    transparency — confirmed via raw escape-code inspection during a live
    test run, matches [anomalyco/opencode#23573](https://github.com/anomalyco/opencode/issues/23573).
    Nothing to fix here; flagged to the user already.
  - `opencode/opencode.json` — a custom `"cekat"` provider (office LLM
    gateway, OpenAI-compatible, `baseURL: https://llm.cekat.id/v1`) with all
    14 models the gateway actually exposes, enumerated by querying its live
    `/v1/models` endpoint (not guessed). API key is `{env:CEKAT_API_KEY}` —
    **never hardcoded in this file**; the real token lives only in
    `~/.zshrc.local` (git-ignored, confirmed absent from the repo via
    `grep -r` before reporting done). `zsh/.zshrc.local.example` got a
    matching placeholder (no real value) so a fresh machine knows the
    variable is expected.
  - `setup.sh` — new symlinks: `k9s/` → `~/.config/k9s`,
    `opencode/tui.json` / `opencode/themes` / `opencode/opencode.json` →
    matching paths under `~/.config/opencode` (individual files, not the
    whole dir — `~/.config/opencode` also holds opencode's own
    auto-generated `opencode.jsonc`/`.gitignore`/session state that
    shouldn't be touched).
  - `development-tools.sh` — added `k9s` to the DevOps `FORMULAE` list, and
    a new step that runs `gcloud components install gke-gcloud-auth-plugin`
    (idempotent, guarded on `command -v gke-gcloud-auth-plugin`) — `kubectl`
    needs this plugin to auth against GKE clusters.
  - `.zshrc` — added a guarded PATH entry for
    `/opt/homebrew/share/google-cloud-sdk/bin`, required for the
    `gke-gcloud-auth-plugin` install above to actually resolve on PATH (see
    OPERATIONS.md's new gotcha — Homebrew's `gcloud-cli` cask only symlinks
    `gcloud`/`gsutil`/`bq`, not later `gcloud components install` output).
  - `README.md` — repo structure listing and both tools tables updated to
    mention k9s, the opencode theme, and the cekat provider.
  - Also landed earlier in this session and **already committed** in
    `1a481ce`: kubectl aliases (`k`, `kg`, `kgp`, etc. in `zsh/aliases.zsh`)
    and a real bug fix in `zsh/completions.zsh` — a second `compinit -C`
    call was silently dropping `kubectl`/`docker` completions (not just the
    new `k` alias; this predates this session). Full detail in
    OPERATIONS.md's Known gotchas, not repeated here since it's settled/shipped.
- **System-level changes made on this machine that git doesn't track** (a
  fresh machine won't have these until it runs `setup.sh`/`development-tools.sh`
  again, except the last one which is machine-only forever):
  - `k9s` installed via `brew install k9s`; `~/.config/k9s` symlinked to
    this repo's `k9s/`.
  - `gke-gcloud-auth-plugin` installed via `gcloud components install`.
  - `~/.config/opencode/tui.json`, `.../themes`, `.../opencode.json`
    symlinked to this repo's `opencode/` (the rest of that directory —
    `opencode.jsonc`, `.gitignore`, session/auth state — is opencode's own
    and was left alone).
  - `~/.zshrc.local` (git-ignored, already held real AWS keys before this
    session — not something this session introduced) got
    `export CEKAT_API_KEY="sk-..."` appended. This is the one item on this
    list a fresh machine actually needs a human to redo manually — it's a
    secret, so it can't live in `setup.sh`/`development-tools.sh`.
  - Verified live, not just written: `k9s` and `opencode` both launched
    under a real pty (`script`) with no config/skin errors; opencode's
    resolved palette matched Catppuccin Mocha exactly via raw ANSI
    inspection; `opencode run -m cekat/anthropic/claude-haiku-4.5 "..."`
    round-tripped a real response through the office gateway.

## Open items / unanswered questions

- The uncommitted work above hasn't been committed — waiting on the user to
  explicitly ask (per this repo's "only commit when asked" convention), not
  an oversight.

## Standing conventions this repo follows

- One folder per tool at repo root; `setup.sh` installs + symlinks
  everything; `development-tools.sh` is a separate optional DevOps layer.
- Theme is Catppuccin Mocha, hand-rolled per tool (not via external theme
  package managers, except where officially blessed) — now also applied to
  k9s and opencode, both transparent to match WezTerm/Neovim.
- Every change gets validated live on this actual machine (syntax check +
  reload + query the running tool) before being reported as done — not
  just written and assumed correct. For Neovim specifically, that means a
  real interactive session (tmux), not headless `-c` command chains — see
  OPERATIONS.md's Known gotchas. For TUI apps generally (k9s, opencode),
  that means launching under a real pty (`script -q /dev/null <cmd>`), not
  a plain piped subprocess — several of these tools behave differently (or
  outright fail with `open /dev/tty: device not configured`) without one.
- Secrets never go in this git-tracked repo — they go in `~/.zshrc.local`
  (git-ignored), referenced from tracked config via env-var syntax (e.g.
  opencode's `{env:VAR_NAME}`) or `export`. `zsh/.zshrc.local.example` gets
  a placeholder (no real value) documenting what's expected, so a fresh
  machine knows what to fill in.
- Only commit/push to git when the user explicitly asks.
- Before reaching for a tool/package by its "obvious" name (terraform,
  docker, etc.), check `development-tools.sh` and `setup.sh` first — this
  repo has already made a deliberate substitution more than once (OpenTofu
  over Terraform, Colima over Docker Desktop, gvm over Homebrew's `go`).
