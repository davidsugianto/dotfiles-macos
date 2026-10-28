# Handover — 2026-10-14 (rtk, uncommitted until reviewed)

rtk-oss 1.0.0 wired into Claude Code, pi and omp by hand (see README "rtk"). Files: `rtk/{rtk.ts,RTK.md}` (verbatim upstream v1.0.0), `setup.sh` (tap, formula, 3 links), `claude/settings.json` (`PreToolUse` `Bash` -> `rtk hook claude`), `claude/CLAUDE.md` (`@RTK.md`), `.gitignore` (`rtk/.rtk-agents`).

- Never run `rtk init -g` (clobbers the settings.json symlink). `rtk init -g [--agent pi|omp] --dry-run` writes nothing; pi/omp print an "ownership state" warning only because no `.rtk-agents` file exists.
- Verified: `rtk hook claude` rewrites `git status`; this Claude session's own Bash calls appear in `rtk gain --history`.
- Open: confirm pi and omp actually rewrite (start a session, run `git status` through bash, check `rtk gain --history` and that no "RTK disabled" status shows). A nested `claude -p` smoke test was blocked by auto mode and not retried.
- Open: rtk 1.0.0 is a day old; watch for churn. jq is no longer needed by the Claude hook (native `rtk hook claude`).

# Handover — 2026-10-13 (pi statusline, uncommitted until reviewed)

The pi statusline now lives in `pi/extensions/statusline/` and replaces `npm:statusline-pi` (dropped from `pi/settings.json` `packages` and `setup.sh` `PI_PACKAGES`; loaded via `extensions` in `pi/settings.json`).

- 2 lines, fixed Catppuccin Mocha colours matching `claude/scripts/claude-statusline`. Profile comes from `~/.pi/profiles/.active`, the roles selector state from pi-model-roles' live `model-roles` status (`auto-selector=enabled|disabled`; the config file's `enabled:` is only a default), the MCP count from `mcp-adapter.json`.
- `/statusline on|off|toggle` command.
- Files: `pi/extensions/statusline/{index,git,format}.ts`. Test: `bash pi/tests/statusline.sh` (the `index.ts` footer part needs bun and is skipped otherwise).
- Refresh: git state is read at most every 5s, and after a `tool_result` at most once per second (trailing re-render). Git calls are read-only (`GIT_OPTIONAL_LOCKS=0`, `-c core.fsmonitor=false`). Cost is recomputed on mount, `message_end`, `model_select` and the 5s tick. The profile name and MCP count are read on the git refresh; the profile is also re-read when pi-profile's `profile` status text changes, so `/profile` shows at once. Roles state comes from the live `model-roles` status.
- README no longer lists `statusline-pi`; the footer hides the `model-roles` and `mcp` (line 2) and `profile` (line 1) extension statuses because it already shows them itself. Other extension statuses (e.g. `subagents:0`) still print below the two lines.

# Handover — 2026-10-08 (Jira MCP)

Added a `jira` MCP server (Atlassian Rovo, `https://mcp.atlassian.com/v1/mcp/authv2`,
browser OAuth + dynamic client registration, also exposes Confluence/Compass) to
`claude/mcp.json`, `omp/mcp.json` and `pi/mcp-adapter.json`, plus a README
"Jira MCP" section. Claude Code has it registered (`claude-mcp-sync`).

Open items: authenticate jira in Claude Code (`/mcp`), omp (`/mcp reauth jira`)
and pi (`/mcp-auth jira`). If an Atlassian admin blocks access, ask them to
enable Rovo MCP. Fallback endpoint `/v1/mcp` if an agent's OAuth can't follow
RFC 9728 discovery.

Deferred review findings (accepted, not fixed yet):
- Rovo vs "Jira-only": Atlassian's only official Jira MCP is the Rovo MCP
  Server (no extra licence on Cloud; rate limits by plan, 500/h on Free). The
  only non-Rovo option is community `sooperset/mcp-atlassian` (local, API token
  or own OAuth app, no dynamic registration). Kept Rovo; revisit if needed.
- README "Jira MCP" product list is incomplete: the server also exposes Jira
  Service Management and Bitbucket tools, not just Jira/Confluence/Compass.
  Optionally document plan rate limits.
- Write access: scopes include `write:jira-work` and Confluence page/comment
  writes, with no toolset filter. Once tool names are visible after login,
  consider `permissions.deny`/`ask` rules for `mcp__jira__` write tools in
  `claude/settings.json` (omp/pi have no per-tool control here).
- Drift: pi 1.0.4 has built-in MCP (`pi mcp …`, reads `~/.pi/agent/mcp.json`),
  but `setup.sh` still says "pi has no built-in MCP support" and the repo uses
  `pi-mcp-adapter`. Decide whether to migrate.
- `shellcheck` isn't installed, so `setup.sh` was only checked with `bash -n`.

# Handover — 2026-10-08

## Session summary: sre-ai-skills onboarding (uncommitted)

`datadog-investigate` and `jira-space-keeper` come from `../sre-ai-skills`. Their `SKILL.md` files there are portable cores with `{{PLACEHOLDERS}}`, so they are not copied. The repo holds machine-local **handlers** that run `preflight.sh` and then read the core live from the clone, so core updates apply with no copying.

- `pi/skills/{datadog-investigate,jira-space-keeper}`: handlers for pi and omp (omp links to them via `omp/skills/*`).
- `claude/skills/...`: Claude handlers (`sonnet`/`opus`, `general-purpose` subagents, `mcp__datadog__` / `mcp__jira__`). `setup.sh` links `claude/skills/*` into `~/.claude/skills` and skips any shared or pi skill of the same name.
- Auto-update: `PREFLIGHT_FF=1` + `PREFLIGHT_LAZY=1` in `.zshrc` (pi, omp) and `claude/settings.json` `env`. preflight fast-forwards the clone only when it is clean, on `main` and merely behind; otherwise it pauses and reports.
- `JIRA_SITE` is `unset` (the skill discovers it). Handlers hardcode `/Users/davidsugianto/...` paths because they are machine-local.
- 2026-10-11: `sre-incident-response` onboarded the same way (`pi/skills/` + `claude/skills/`; `~/.agents/skills` and `~/.claude/skills` entries are symlinks into the repo). `SLACK_CHANNEL`, `SLACK_CANVAS_ID` and `SLACK_CANVAS_ROW` are unset (no Slack posting or canvas watch) until set in both handlers; `HUMANIZER_SKILL` is `none`. Old stale copies were not kept in the repo.
- 2026-10-12: all sre-ai-skills cores, including `frontend-engineer` (kept because `investigation-report` and `k8s-cost-review` depend on it), now have handlers in both `pi/skills/` and `claude/skills/` (adopted `frontend-engineer`, `investigation-report`, `k8s-cost-review`, `k8s-triage`, `matlev-rater`, `onboard-skills`, `personal-skill-generator`; new `sanitize-alarm`). Former loose dirs in `~/.agents/skills` were moved to `~/.dotfiles-backup/*-sre-skills/`. Drift synced to current cores: descriptions of `investigation-report`, `k8s-triage`, `pi/datadog-investigate`; added `INVESTIGATION_OUTPUT_DIR` (default `tmp/sre-reports/investigations`); dropped dead `REPORT_SKILL` from `k8s-triage`. `sanitize-alarm` `DENYLIST_FILE` is `~/.agents/private/sanitize-alarm/denylist.txt` (outside git, not created yet: the skill refuses to run until it exists, owner-only).
- Descriptions: pi rejects descriptions over 1024 chars or containing `: `. The upstream cores of `datadog-investigate`, `investigation-report`, `k8s-triage`, `sanitize-alarm` and `sre-incident-response` break that, and sre-ai-skills is deliberately left unchanged, so the pi and claude handlers carry shortened descriptions (`check-skill.sh` reports a description mismatch). `sre-skills-sync` prints a NOTE for exactly that case and DRIFT for any other mismatch. If a core's description changes, refresh the shortened copy by hand.
- `sre-skills-sync` (`pi/scripts/`, linked to `~/.local/bin`, run by `setup.sh`): fast-forwards sre-ai-skills, runs `check-skill.sh` on every handler, flags cores with no handler and missing links. Never edits handlers.
- Regenerate a handler from `personal-skill-generator/templates/handler.SKILL.md` if a core adds placeholders; `check-skill.sh <core> <handler>` flags drift.

Open:
- (Done) The old untracked handler `~/.agents/skills/datadog-investigate` is removed.
- Start new pi, omp and Claude sessions and confirm both skills are listed.

## Session summary: Claude Code mirrors pi (uncommitted)

Added `claude/`, which gives Claude Code pi's workflow, prompt templates, model
roles and model profiles. It's linked into `~/.claude/` (already applied on
this machine). See `docs/claude-workflow-guide.md`.

- `claude/CLAUDE.md`: port of `PI.md`, using TodoWrite, the Agent tool and role subagents, and `~/.claude/handoffs`.
- `claude/commands/`: port of `pi/prompts/` (`$ARGUMENTS`, `~/.claude/CLAUDE.md`), plus `/handoff`. `/plan` is pinned to `claude-opus-5-5[1m]`.
- `claude/model-roles/{default,personal-labs,work-cekatai-default}/`: role subagents generated from `pi/model-roles/*.yaml` (same descriptions, models and effort; the work set has no `web` role). `claude-roles` repoints the `~/.claude/agents` symlink.
- `claude/profiles/*.json` + `claude-profile`: `--settings` overlays, Anthropic-only except the opt-in `work-cekatai-default` profile via `claude-work`.
- `claude/settings.json`: the live file captured wholesale (Orca + Herdr hooks, autoMode, statusLine — now `claude-statusline`, a custom two-line script, replacing ccstatusline). I added `model: claude-sonnet-5-5[1m]`, `effortLevel: high`, and `env` `CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000` / `CLAUDE_CODE_AUTO_COMPACT_WINDOW=922000` to match the cekat work models (922K/128K). The pre-link original is backed up in `~/.claude/backups/dotfiles-claude-20261008-121957/`.
- `agent/skills/herdr-delegate` (moved from `pi/skills` 2026-10-27): `KIND` now accepts `claude`, so a Claude orchestrator starts Claude workers.
- `setup.sh`: Claude links, per-entry skill links into `~/.claude/skills` (that directory keeps claude.ai's `synced/`), seeding of `claude-roles default`, the `claude-work` link into `~/.local/bin`, and `herdr integration install claude`.

Verified: the smol profile runs on Haiku 4.5; the default runs on `claude-sonnet-5-5[1m]`; the smol and slow subagents run on haiku and sonnet[1m]; `/plan` runs on Opus 5.5 and stops at the gate.

- MCP: `claude/mcp.json` holds the same Datadog and Slack servers as `pi/mcp-adapter.json`. `claude-mcp-sync` (run by `setup.sh`) registers them at user scope through `claude mcp add-json`. It can't be a symlink because the servers live in `~/.claude.json` (runtime state). The Slack secret goes to the keychain through `MCP_CLIENT_SECRET`. Both servers are registered and still need `/mcp` → Authenticate.
- The `setup.sh` skills loop now prunes dangling `~/.claude/skills` links.
- `claude/themes/`: the 8 Catppuccin themes (+ MIT licence) vendored from matcra587/claude-themes `plugins/catppuccin` @ 4ae1032, linked to `~/.claude/themes` (already applied). `settings.json` sets `"theme": "custom:catppuccin-mocha"` (slug = file stem). Vendored rather than `/plugin install` so it is versioned with the repo and needs no marketplace.

- 2026-10-11, work gateway: added `claude/model-roles/work-cekatai-default/` (Luna for smol/commit, Sol for slow/plan/task; no `web`), `claude/profiles/work-cekatai-default.json` (`ANTHROPIC_BASE_URL=https://llm.cekat.id`, Luna as model, Sonnet/Opus/Haiku default-model vars mapped to Luna/Sol/Luna; no secrets) and `claude/scripts/claude-work` (needs `$CEKAT_API_KEY` from `~/.zshrc.local`, exported as `ANTHROPIC_AUTH_TOKEN`). Use `claude-roles work-cekatai-default` (alias `work-default`), then `claude-work`. It is an overlay, not a separate config dir (skills, MCP, settings, hooks and history are shared), and `claude-roles` repoints the global `~/.claude/agents` symlink, so it affects every open session until `claude-roles personal`. Claude Code talks the Anthropic Messages API; the gateway's LiteLLM `/v1/messages` route serves it. The model ids carry a `[1m]` suffix (stripped before the request; makes Claude Code assume a 1M window instead of 200K) and the profile sets `CLAUDE_CODE_AUTO_COMPACT_WINDOW=922000` / `CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000` to match the real 922K/128K limits; keep these, they are not accidental (max output still displays as 32K). Verified 2026-10-11: plain + tool-use calls on Luna and Sol, and `claude-work -p` ran a file read. Not yet tested: subagents on the gateway models. Caveats: run it via `claude-work`, not `claude-profile` (no token), and don't run `/superagent` from a `claude-work` session (workers are plain `claude --agent <role>` and get neither the gateway env nor the overlay).

Open:
- Authenticate datadog and slack via `/mcp`.
- Run `/config` interactively once and confirm `~/.claude/settings.json` is still a symlink afterwards.
- Run `/superagent` with Claude workers end to end inside Herdr (not tested yet).
- Haiku 4.5 has no effort parameter, so Haiku profiles and agents leave effort out.

## Session summary: prompt-forge skill (uncommitted)

2026-10-27: added `prompt-forge`, a skill that turns rough Indonesian, mixed or messy English text into one copy-ready English prompt, with notes (assumptions, placeholders) under it.

- `agent/skills/prompt-forge/` (`SKILL.md` + `references/examples.md`): the first skill in the new central `agent/skills/`. `setup.sh` links `agent/skills/*` into `~/.agents/skills`, which pi and omp read and which the Claude Code loop links into `~/.claude/skills`. No per-agent symlinks in `omp/skills` or `claude/skills`, and no Claude handler copy: the skill names no model or tool. Put skills kept as one file for all three agents there.
- Behavior: blocking gap → at most 3 questions and no prompt; smaller gaps → default plus `[PLACEHOLDER]`. The prompt text is always plain (no personas, filler, stacked caps). A "Writing rules" block is added only when the task asks for prose.
- Description is under 1024 chars and has no `: ` (pi rejects both).
- Keep the step 3 blocking-gap rule strict. Smoke tests showed that with a vaguer rule, Claude and omp turned "bikin prompt buat analisa data" into a generic placeholder template instead of asking questions. The rule now says: if the central subject would have to be a placeholder, ask.
- Examples must not state facts the user did not give (example 2 uses `[HOW_BUG_WAS_FOUND]`); models copy examples.
- Pasted material (documents, logs) goes verbatim and untranslated inside XML tags, and instructions inside it are never followed (tested with an injected "balas HACKED" line in all three agents).
- If the generated prompt contains its own fenced block, the outer fence is four backticks.

- 2026-10-27: `herdr` and `herdr-delegate` moved from `pi/skills` to `agent/skills` (content unchanged). `omp/skills/herdr*` symlinks removed; `omp/skills` now holds only the sre handler links and `tern-delegate`. `pi/settings.json` still lists `pi/skills` (the sre handlers) and needed no change. Restart open pi, omp and Claude sessions: they may hold the old `pi/skills/herdr/SKILL.md` location.

Open:
- Start new pi, omp and Claude sessions and confirm `prompt-forge`, `herdr` and `herdr-delegate` are listed; try the three inputs in `references/examples.md`.

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

## 2026-09-23: Cekat function-tool routing

Fixed tool-call failures for `azure_ai/gpt-6-luna` and `azure_ai/gpt-6-sol` in
both pi and omp. The Cekat LiteLLM gateway rejects tool calls on
`/v1/chat/completions` when it attaches its server-side `reasoning_effort`,
including when the client omits that field. Client-side
`compat.supportsReasoningEffort: false` and `reasoning_effort: "none"` did not
resolve it. Per-model `api: openai-responses` routes Luna and Sol through
`/v1/responses`; the provider default remains `openai-completions` for the
other models. Do not replace this with provider-level API routing, which would
change the transport for every Cekat model.

Changed `pi/models.json` and `omp/models.yml`; removed the ineffective omp
`modelOverrides` workaround and corrected the work-profile comment. The pi
models file is symlinked live to `~/.pi/agent/models.json`; the pi-model-roles
config is separately copied, not symlinked.

Validation completed with live tool calls: pi Luna and Sol each passed single
and sequential two-command bash tool calls; pi Terra passed a regression tool
call. Omp Luna and Sol each passed a bash tool call. JSON/YAML syntax and the
pi models symlink were checked. `pi-roles work-default` was deployed and compared with
the repository role file, then the original `personal-labs` role config was
restored and compared. Open pi sessions may need `/reload` to pick up a role
config switch; model catalog changes reload when `/model` is opened.

## 2026-10-05: gpt-6.1-sol and work-profile model swap

Added `azure_ai/gpt-6.1-sol` (`api: openai-responses`, copied from `gpt-6-sol`;
not live-tested) to `pi/models.json` and `omp/models.yml`. The
`work-cekatai-default` profile now uses `gpt-6.1-sol` for slow/plan/task and
`gpt-6-luna` for default/smol/commit in both tools (omp: `omp/model-profiles/`;
pi: `pi/model-roles/` + `pi/profiles/`). `gpt-5.6-terra` is no longer referenced
by the work profile but stays in the model catalogs. Effort: `default`
(Luna), `slow`, `plan` = high; omp via `:high` suffix, pi via `effort:`.
pi `settings.json` now has `defaultModel: azure_ai/gpt-6-luna` and
`defaultThinkingLevel: high`. Redeploy pi roles with `pi-roles work-default` + `/reload`.

## 2026-10-13: work profile rename and work-cekatai-superpower

Renamed `work-cekataiofficial` -> `work-cekatai-default` everywhere (pi, claude,
omp; older entries in this file were rewritten to the new name). Added
`work-cekatai-superpower` in all three: default/slow/plan/task = `gpt-6.1-sol`
(slow/plan high), smol = `gpt-6-luna` high, commit = `gpt-6-luna`. Deploy with
`pi-roles work-superpower`, `claude-roles work-superpower` + `claude-work work-superpower` (the short aliases are `work-default`/`work-superpower` in both tools), or
`/profile work-cekatai-superpower` in omp/pi. The old name is not kept as an
alias. Not live-tested against the gateway. AWS/git `cekataiofficial` names are
the org, unchanged.

## 2026-10-13: pi work sets get a `web` role

Added `web` = `azure_ai/gpt-6-luna`, effort high, to `pi/model-roles/work-cekatai-default.yaml`
and `work-cekatai-superpower.yaml` (pi only). Previously web-style tasks fell
through to `default`. Claude Code's work sets still have no `web` role and omp's
work profiles still fall back to the global `web` role. Redeploy with
`pi-roles work-default` / `pi-roles work-superpower` + `/reload`. Not live-tested
against the gateway.

## 2026-10-28: gpt-6.1-terra as the work-cekatai-default default role

Added `azure_ai/gpt-6.1-terra` (`api: openai-responses`) to `pi/models.json` and
`omp/models.yml`. Cost comes from the gateway `/model/info` (input 2, output 7.5,
cacheRead 0.1, cacheWrite 2.5 per 1M). The gateway reports no context or output
limits, so `contextWindow` 922000 / `maxTokens` 128000 (and pi's
`thinkingLevelMap`) are copied from `gpt-6.1-sol` and unverified. The
`work-cekatai-default` `default` role now uses Terra in pi (`effort: high`,
`pi/model-roles/`) and omp (`:auto`, `omp/model-profiles/`). Unchanged: pi's
`pi/profiles/work-cekatai-default.json` session model and `settings.json`
`defaultModel` (both still Luna), the pi role selector (Luna), and Claude Code.
Redeployed pi roles with `pi-roles work-default` (`/reload` open pi sessions).
Not live-tested against the gateway.

## 2026-10-28: gpt-6-luna withdrawn from the cekat key; Terra replaces it

The gateway started returning 403 for `azure_ai/gpt-6-luna` ("not available for this API key");
the key's `/v1/models` now lists only `gpt-5.6-luna`, `gpt-5.6-terra`, `gpt-6.1-sol` and
`gpt-6.1-terra`. Every live Luna use moved to `azure_ai/gpt-6.1-terra`:
- pi: both work role sets (selector, smol, commit, web; former `off` effort -> `low`, since
  Terra rejects `off`; the selector drops from `high` to `low` because Terra really thinks,
  unlike Luna, and classification runs per prompt under the 8 s `selectorTimeoutMs`),
  `settings.json` `defaultModel`, `pi/profiles/work-cekatai-default.json`.
  Tests updated first (`pi/tests/settings-defaults.sh`, `pi/tests/pi-worker-model.sh`).
- omp: work profiles (smol, commit, web), `config.yml` `retry.fallbackChains.web` -> [Sol, Terra],
  plus a new `cekat/azure_ai/gpt-6-luna` -> [Terra] chain for leftover Luna requests.
- Claude Code: work-cekatai-* `smol`/`commit` agents and the Haiku/small-fast (and default-set
  Sonnet/main) model vars in `claude/profiles/`.
- opencode: the cekat model list swaps Luna for `gpt-6.1-terra`. It reaches cekat via
  `@ai-sdk/openai-compatible` (`/v1/chat/completions`), which the gateway rejects for tool calls
  on the GPT-6 models, so Terra/Sol tool calls likely fail there. Config left as is; nothing
  selects them by default.
The Luna catalog entries stay in `pi/models.json` / `omp/models.yml` (the omp fallback key needs
it). Terra costs more than Luna (output $7.5 vs $0.75 per 1M). Redeployed pi roles with
`pi-roles work-default`; restart `claude-work` sessions and `/reload` pi. Not live-tested.

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
