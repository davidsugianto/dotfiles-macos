# AI agents

Everything about the agent CLIs (Claude Code, opencode, omp, pi), their workflow, model roles, Herdr, rtk and Orca. Back to the [README](../README.md).

## Agent CLIs

- **[opencode](https://opencode.ai)** (AI coding agent CLI): `opencode`, an alternative agent with a different model/provider story; themed Catppuccin Mocha (transparent), matching WezTerm/Neovim/k9s (`opencode/`); also configured with a custom "cekat" provider (office LLM gateway) — its API key is read from `$CEKAT_API_KEY`, set in the git-ignored `~/.zshrc.local`, never committed

- **[omp](https://omp.sh)** (AI coding agent CLI): Another alternative agent (`omp`, aka "Oh My Pi") — subagents, plan mode, LSP/DAP wired in; installed via `can1357/tap/omp`; per-role model config (`omp/`) picks Sonnet 5.5 by default, Haiku 4.5 for smol/commit tasks, Opus 5.5 (high) for slow/plan (all Claude models via the Anthropic OAuth login, never the cekat gateway); themed Catppuccin (transparent status line), matching WezTerm/Neovim/k9s/opencode; web search tries Anthropic's native tool first (already authenticated, no extra key), then free keyless fallbacks (duckduckgo, startpage, google); also configured with the same custom "cekat" provider (office LiteLLM gateway) as opencode — `omp/models.yml`, same `$CEKAT_API_KEY` env var; [omp-model-profiles](https://github.com/rezhajulio/omp-model-profiles) plugin (installed via `omp plugin install`, needs `bun`) adds `/profile edith-default` / `/profile edith-superpower` (the Anthropic roles above, mirroring Claude Code's sets) and `/profile work-cekatai-default` (internal GPT-6.1 Terra/Sol via the cekat gateway — Terra for default/smol/commit/web, Sol for slow/plan/task) to switch the whole role set in-session — `omp/model-profiles/`

- **[pi](https://pi.dev)** (AI coding agent CLI): The minimal upstream agent `omp`/"Oh My Pi" builds on; installed via `brew install pi-coding-agent`; task-based model routing across the same default/smol/slow/plan/commit/task/web split as `omp/`, via the [pi-model-roles](https://github.com/spksoft/pi-model-roles) extension (`pi/model-roles/`, deployed with `pi-roles work-default\

- **[Orca](https://www.onorca.dev)** (Agent Development Environment (ADE)): Desktop app for running Claude Code/opencode/omp in parallel, each in its own isolated git worktree, with diffs viewable side by side; installed via `stablyai/orca/orca`; launch shortcut `alt+shift+r` (see [aerospace/aerospace.toml](../aerospace/aerospace.toml)); default tab agent set to `omp` so new tabs use the internal "cekat" LLM gateway by default, personal Claude Code still one command away — see below

## Config layout

- `herdr/` — config.toml (Dracula theme, keys, sidebar/tab bar, session resume) + sounds/{done,request}.mp3 (synthesized agent-done / needs-input chimes), linked to ~/.config/herdr/ (only these two — herdr keeps sockets/logs/session.json there)
- `agent/` — skills/ (skills shared as one file by Claude Code, pi and omp: herdr, herdr-delegate, prompt-forge, prompt-openbot), linked into ~/.agents/skills/ by setup.sh; agent-selection.md (planner/executor/scanner model tiers, the AGENT_SELECTION_FILE of the core-ai-skills handlers, read by absolute path)
- `omp/` — config.yml (modelRoles, webSearchOrder) + models.yml (custom "cekat" provider) + mcp.json (Datadog + Jira + Slack + Cloudflare MCP servers) + themes/*.json (custom omp themes, e.g. atom-one-dark) + model-profiles/*.yml (edith-default, edith-superpower, work-cekatai-default, work-cekatai-superpower) + commands/ (omp-only slash commands: /superagent via Tern) + skills/ (symlinks to the pi/skills sre handlers datadog-investigate and jira-space-keeper, plus tern-delegate), linked to ~/.omp/agent/ (incl. themes/, commands/, skills/) and ~/.omp/model-profiles/
- `pi/` — settings.json + models.json (custom "cekat" provider) + mcp-adapter.json (Datadog + Jira + Slack + Cloudflare MCP servers, via pi-mcp-adapter) + themes/*.json (switchable Pi themes) + model-roles/*.yaml (work-cekatai-default, work-cekatai-superpower) + profiles/*.json + prompts/*.md (slash commands) + skills/ (core-ai-skills handlers) + extensions/ (subagents-pi vendored, not on npm; statusline footer, herdr-agent, notify, todo, manage-handoff), linked to ~/.pi/agent/ and ~/.pi/profiles/
- `claude/` — Claude Code mirror of pi/: CLAUDE.md (PI.md workflow) + commands/*.md (pi prompts as slash commands) + model-roles/{edith-default,edith-superpower,work-cekatai-default,work-cekatai-superpower}/*.md (role subagents) + profiles/*.json (`--settings` overlays, incl. `work-cekatai-default.json` for the cekat gateway) + scripts/ (claude-roles, claude-profile, claude-work) + settings.json, linked to ~/.claude/ and ~/.local/bin/
- `rtk/` — rtk.ts (pi + omp extension, upstream v1.0.0) + RTK.md (Claude awareness note), linked to ~/.pi/agent/extensions/, ~/.omp/agent/extensions/ and ~/.claude/

## Claude Code workflow (mirrors pi)

`claude/` gives Claude Code the same workflow, prompt templates, model roles
and model profiles as `pi/`, using Claude Code's own features. Full guide:
[docs/claude-workflow-guide.md](claude-workflow-guide.md).

| pi | Claude Code |
|---|---|
| `PI.md` | `claude/CLAUDE.md` → `~/.claude/CLAUDE.md` |
| `pi/prompts/*.md` | `claude/commands/*.md` → `/plan`, `/plan-deep`, `/execute`, `/superagent`, `/delegate`, `/review`, `/fix`, `/test`, `/commit`, `/do-handoff`, `/work-on-handoff`, `/handoff` |
| pi-model-roles + `pi-roles` | role subagents `smol`/`slow`/`plan`/`commit`/`task`/`web` in `claude/model-roles/<set>/`; `claude-roles edith-default\|edith-superpower\|work-cekatai-default\|work-cekatai-superpower` (aliases `default`, `personal`, `work-default`, `work-superpower`) repoints `~/.claude/agents`; the work set has no `web` role |
| pi-profile `/profile` | `claude-profile <name>` (`claude --settings claude/profiles/<name>.json`); aliases `ccp`, `ccplan`, `ccslow`, `ccsmol`; `claude-work` runs Claude through the cekat gateway with `profiles/work-cekatai-default.json`, or `claude-work work-superpower` for `work-cekatai-superpower.json` (needs `$CEKAT_API_KEY`) |

The default setup is Anthropic-only (`/login` subscription); the opt-in
`work-cekatai-default` role set + `claude-work` route a session through the
internal cekat LiteLLM gateway instead (see the guide). Sonnet/Opus 5.5 run
with 1M context (`[1m]`), and `settings.json` sets 128K max output and a
922K auto-compact window to match the cekat work models in `pi/models.json`.
`setup.sh` also links every shared skill (`~/.agents/skills`, which also holds
the `agent/skills` and `pi/skills` entries) into `~/.claude/skills/` one by one, so claude.ai's `synced/` dir is left alone.

## pi model-role switching

`pi/` mirrors `omp/`'s modelRoles concept using two vanilla-`pi` extensions,
since `pi` itself has no built-in role system:

| Mechanism | Extension | What it does |
|---|---|---|
| Automatic task routing | [pi-model-roles](https://github.com/spksoft/pi-model-roles) | Classifies each submitted task and auto-picks its model/effort from `~/.pi/agent/extensions/pi-model-roles/config.yaml` — the `default`/`smol`/`slow`/`plan`/`commit`/`task`/`web` split, same tiering as `omp/config.yml` |
| Manual identity switch | [pi-profile](https://github.com/Eddie0521/pi-profile) | `/profile <name>` inside pi — one profile per role (`pi/profiles/`) plus `work-cekatai-default`/`work-cekatai-superpower` account switches |

Swapping the whole work role set (the `pi-model-roles` equivalent
of omp's `/profile <name>`) needs a
shell command, not a slash command: `pi-model-roles` refuses to save through
a symlinked `config.yaml`, so `pi/model-roles/*.yaml` are copied into place
rather than linked.

```sh
pi-roles work-default    # cekat gateway (office GPT-6.1 Terra / GPT-6.1 Sol) — work-cekatai-default
pi-roles work-superpower # cekat gateway, Sol-heavy — work-cekatai-superpower (Sol for default/slow/plan/task, Terra for smol:high/commit/web)
```

pi only runs the cekat (work) models; the Anthropic role sets and profiles live
in omp and Claude Code. Pi's global startup default is
`cekat/azure_ai/gpt-6.1-terra` at `high` effort (Terra supports thinking). This startup default is independent
of the copied model-role set (`pi-roles work-default` / `work-superpower`). omp's `:auto`
effort has no pi equivalent and custom roles can't `inherit`, so `:auto` maps
to `medium`.

Run `/reload` in every open `pi` session afterwards — `pi-model-roles` has
no file watcher. `pi-roles` is a plain script (`pi/scripts/pi-roles`,
linked to `~/.local/bin/pi-roles`), so `git diff` in this repo always shows
exactly which role set is checked in as the machine default.

## Cekat model tool-call routing

The Cekat LiteLLM gateway rejects function-tool requests for `azure_ai/gpt-6-luna`,
`azure_ai/gpt-6-sol`, and `azure_ai/gpt-6.1-sol` on `/v1/chat/completions`: LiteLLM
attaches a server-side `reasoning_effort` value, even when the client omits it.
Setting `compat.supportsReasoningEffort: false` or sending
`reasoning_effort: "none"` does not avoid this gateway behavior. Route these
models through the Responses API instead by setting `api: openai-responses` on
their model entries in both `pi/models.json` and `omp/models.yml`. Keep the
provider default as `openai-completions` for the other models. (`gpt-6.1-sol`
and `gpt-6.1-terra` were given the same routing by assumption, not verified
against the gateway.) `azure_ai/gpt-6-luna` is no longer served to the key
(403); the work sets moved to `azure_ai/gpt-6.1-terra`.

The pi model catalog reloads when `/model` is opened; use `/reload` in open
sessions if needed. After changing pi model-role sets with `pi-roles work-default`
or `pi-roles work-superpower`, run `/reload` in each open session to load the copied role
config.

## pi status & subagent extensions

All from [luongnv89/pi-extensions](https://github.com/luongnv89/pi-extensions)
(MIT):

| Extension | What you get | Source |
|---|---|---|
| [timestamp-pi](https://github.com/luongnv89/pi-extensions/tree/main/extensions/timestamp-pi) | Timestamp under every message + a prompt-cache TTL countdown in the footer | npm |
| [@tintinweb/pi-subagents](https://github.com/tintinweb/pi-subagents) | Orchestration engine — spawning, FleetView, the `Agent` tool | npm |
| [statusline](../pi/extensions/statusline) | Two-line footer in the Claude statusline style, fixed Catppuccin Mocha colours: repo/branch/dirty, model · thinking, cost, profile, ctx bar, CPU/MEM, roles state, MCP count | **in-repo**, loaded via `extensions` in `pi/settings.json` |
| [subagents-pi](../pi/extensions/subagents-pi) | Fleet metrics panel (context, TPS, model, thinking) per managed subagent — companion to the extension above | **vendored**, not on npm |

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

Toggle commands once installed: `/statusline` (in-repo footer, `pi/extensions/statusline`),
`/timestamp-pi`, `/subagents-pi`, `/subagents-pi-refresh`.

## rtk (Claude Code + pi + omp)

[rtk](https://github.com/rtk-ai/rtk) rewrites an agent's shell commands to
`rtk <cmd>` (`git status` -> `rtk git status`) so the model reads condensed
output; upstream claims 60-90% fewer tokens on common dev commands. Only
Bash tool calls are affected, not Read/Grep/Glob.

- Edition: `rtk-ai/tap/rtk-oss` (Apache-2.0 only, hooks + filters, no BUSL
  compression engine), installed by `setup.sh`. `rtk-proxy` and `rtk claude`
  are not used.
- Claude Code: `claude/settings.json` has a `PreToolUse` `Bash` hook running
  `rtk hook claude`; `claude/CLAUDE.md` ends with `@RTK.md` (`rtk/RTK.md`
  linked to `~/.claude/RTK.md`). The hook only auto-allows a rewritten command
  when one of your allow rules matches; otherwise Claude still prompts.
- pi and omp share `rtk/rtk.ts` (verbatim from upstream `hooks/pi/rtk.ts` at
  v1.0.0), linked into both `extensions/` dirs; omp loads it through its
  pi-compat layer. The extension is fail-open and shows "RTK disabled" in the
  status line if `rtk` is missing or older than 0.23.0.
- **Do not run `rtk init -g`.** It rewrites `~/.claude/settings.json`
  atomically, which can replace the repo symlink with a plain file. The hand
  wiring above matches its layout, so `rtk init -g --dry-run` reports nothing to
  change. To upgrade the extension, copy the new upstream file over `rtk/rtk.ts`.
- Usage: `rtk gain` / `rtk gain --history` (savings), `rtk bypass <cmd>` (one
  unfiltered command), `RTK_DISABLED=1` (pi/omp extension off). Telemetry is off
  by default; leave it.

## Herdr superagent (pi + omp + claude)

[Herdr](https://herdr.dev) runs agents in persistent workspaces/tabs/panes and
exposes them through the `herdr` CLI. Start `herdr`, then `pi` or `omp` in a
pane. Step-by-step usage (plan → execute/superagent → review → fix → test →
commit, with an end-to-end example): [docs/pi-workflow-guide.md](pi-workflow-guide.md);
every prompt annotated: [docs/pi-prompts.md](pi-prompts.md).

The Herdr desktop app (`Herdr.app`) is not managed by the `herdr` TUI server: its panes set `HC_TERMINAL_SOCKET`/`HC_TERMINAL_ID` and are driven with `hc`. `herdr-delegate` detects that and runs section 12 (workers as `sa-<id>-<n>` terminals labelled `sa=<id>`, no workspace/tab); the pi `/herdr-agents` command and footer need the `herdr` TUI. The app's Catppuccin Mocha theme and transparency (`herdr-app/`, merged by `setup.sh`) are described in [OPERATIONS.md](../OPERATIONS.md#herdr-desktop-app).

omp has its own `/superagent` that runs workers in Tern tabs instead of Herdr; see [docs/omp-workflow-guide.md](omp-workflow-guide.md).

| Command / file | What it does |
|---|---|
| `/superagent <plan>` | Slices an approved plan into file-disjoint workers, starts one pi/omp worker per tab in a new `sa-<id>` workspace, waits, re-runs validation, closes the workspace. Stops at the plan GATE first. |
| `/delegate [constraints]` | Same, using the open `/todos` items as slices; toggles each todo after its worker is verified. |
| `/herdr-agents` | Lists live Herdr agents. The footer shows `sa ● N working · ◐ N blocked · ✓ N ready` while workers run, with a warning when one blocks. |
| `/todos`, `/handoff`, `/do-handoff`, `/work-on-handoff` | Session todo list; handoff docs in `~/.pi/agent/handoffs` (`/handoff` archives `status: done` ones). |
| `agent/skills/herdr-delegate/SKILL.md` | The orchestration procedure both agents follow. Briefs/results live in `$TMPDIR/superagent/<id>/`. |
| `agent/skills/herdr/SKILL.md` | Vendored `herdr --skill` output plus `LOCAL:` edits — re-sync after `brew upgrade herdr`. |

pi workers pick their model by role (`task` default, `slow`, `smol`): the
orchestrator runs `pi-worker-model <role>`, which reads the active `pi-roles`
set and prints the provider, model and thinking effort to pass at start. omp
workers and roles that don't resolve inherit `defaultModel`; a model named in
the command wins over the role.

Herdr's agent-state integrations (`~/.pi/agent/extensions/herdr-agent-state.ts`,
`~/.omp/agent/extensions/herdr-omp-agent-state.ts`) are owned by Herdr and
installed by `setup.sh`; don't vendor them. `notify.ts` sends OSC 777 desktop
notifications only outside Herdr (inside, Herdr's own toasts apply).

Herdr reports pi's project-trust dialog as `idle`, not `blocked`, and a
prompt sent to it presses Enter on **Trust**. The delegate skill checks each
worker's screen before dispatching; workers started in an already-trusted
repo never see the dialog.

## Browser Relay for pi

[Browser Relay](https://github.com/reliefeai/browser-relay) lets pi work in
existing, logged-in Google Chrome tabs using its `browser-relay` CLI and a
skill installed at `~/.agents/skills/browser-relay` (shared with pi through
`~/.pi/agent/skills`). `setup.sh` installs Node.js, the CLI and its macOS
launchd service, and the skill. It is **not** a `pi install` package; no
separate browser or API key is needed. Only the localhost relay is used;
**do not enable Remote Relay** in the extension unless you intend to expose
browser control through a remote service and manage its device credential.

Finish the browser setup manually after running `setup.sh`:

1. Run `browser-relay path` to print the unpacked Chrome extension directory.
2. Open `chrome://extensions`, enable **Developer mode**, choose **Load
   unpacked**, and select that directory. Approve the extension's debugger
   access only for tabs you want the agent to control.
3. Run `browser-relay doctor` and `browser-relay tabs` to verify that the
   local service and extension are connected and at least one tab is attached.
   If launchd is unavailable, run `browser-relay` in a separate terminal and
   retry. Restart pi (or `/reload`) to load the new skill.

Browser Relay can read pages and act using your logged-in browser privileges.
Start with a read-only prompt such as "Use Browser Relay to tell me the title
and URL of my current Chrome tab; do not navigate." Do not attach tabs with
sensitive data unless you trust the agent with that data.

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
