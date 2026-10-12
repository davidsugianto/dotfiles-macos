---
name: sanitize-alarm
description: Sanitize monitoring alarms, one at a time or in bulk, in three modes - redact (remove credentials, personal data, and for sharing outside also addresses and hostnames), normalize (turn raw alarm payloads and monitor messages into one clean standard shape), and hygiene (find noisy, flapping, duplicate, unowned, stale, or muted monitors and propose fixes). A bulk run, such as "all alarms with this tag", first builds a visual HTML change plan of every proposed change, then waits for the runner's explicit approval before changing anything, and applies only approved items. Takes an alarm pasted as text or JSON, a Datadog monitor, event, or incident link, a monitor name or ID, or a tag or search scope. Use whenever the user says "sanitize this alarm", "redact this alert", "make this safe to share", "normalize the alarms", "alert hygiene", "noisy alerts", "flapping monitors", "which monitors are useless", or "clean up all alarms with tag X", or pastes an alarm to post somewhere.
model: sonnet
effort: high
---

# sanitize-alarm (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/sanitize-alarm main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/sanitize-alarm/SKILL.md` in full, plus any file in that directory it tells
   you to read (paths in the core are relative to the core directory). If the core
   is missing, stop and tell the user the skills repo is not at that path. Do not
   improvise the skill from memory.
3. Wherever the core uses a double-brace placeholder, substitute its value from
   the tables below. If the core uses a placeholder with no row here, this
   handler is out of date: stop and name the missing variable.
4. Run every shell command for this skill from `WORKDIR`, using absolute paths,
   and write outputs under `OUTPUT_DIR` unless the core says otherwise.
5. Resolve secrets only as described under "Secrets" below, and never print them.
6. When the core tells you to spawn subagents, give each one the model in
   `SUBAGENT_MODEL` (and the type in `SUBAGENT_TYPE` if the table defines one).
   Never let a subagent inherit this skill's model unless the core says to.
7. Claude Code loads MCP tools on demand: before the first Datadog call, load
   the schemas you need with ToolSearch (`select:mcp__datadog__<tool>,...`), and
   tell every executor subagent to do the same. If a needed tool does not resolve,
   say so and stop, as the core requires.
8. Follow the core's instructions from there.

## Local variables

| Variable | Value | Purpose |
|---|---|---|
| `SKILL_NAME` | `sanitize-alarm` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/sanitize-alarm` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `sonnet` | Model for this skill (same as frontmatter) |
| `EFFORT` | `high` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `sonnet` | Model passed to subagents this skill spawns, as the subagent tool accepts it |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/sanitize-alarm` | Where this skill writes its outputs |
| `RUN_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/sanitize-alarm/runs` | Private folder for one run's working files; a new owner-only subfolder per run |
| `DENYLIST_FILE` | `/Users/davidsugianto/.agents/private/sanitize-alarm/denylist.txt` | Private file of terms that identify the organisation. Not in git. UNSET until the person creates it (owner-only); the skill refuses to run until it exists |
| `REPORT_SKILL` | `investigation-report` | Skill that writes the HTML report, using its change-plan profile |
| `PROSE_SKILL` | `none` | No prose-cleanup skill installed on this machine |
| `CHART_SKILL` | `none` | No chart skill installed on this machine |
| `SUBAGENT_TYPE` | `general-purpose` | Subagent type for executors; it must have the monitoring MCP tools |
| `MAX_EXECUTORS_PER_ROUND` | `4` | Most executors to run in parallel |
| `MONITORS_PER_EXECUTOR` | `25` | Most monitors one executor reviews |
| `QUERIES_PER_MONITOR` | `12` | Most queries an executor may spend on one monitor |
| `LOOKBACK_DAYS` | `30` | History window for noise measurements |
| `NOISY_TRANSITIONS` | `20` | Alert transitions in the window above which a monitor counts as noisy |
| `FLAP_MINUTES` | `15` | An alert that recovers within this many minutes counts as a flap |
| `DATADOG_MCP_PREFIX` | `mcp__datadog__ (tools are mcp__datadog__<tool>)` | Prefix of the monitoring MCP's tool names in this runtime |
| `DATADOG_SITE` | `us5.datadoghq.com` | Monitoring site the connected MCP serves, used to recognise links |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own; Datadog access uses the MCP server's browser OAuth session |
