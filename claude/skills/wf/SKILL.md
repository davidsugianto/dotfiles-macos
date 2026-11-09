---
name: wf
description: Run a task as a Claude Code dynamic workflow with cost-aware defaults (/wf <task>), or show the token cost of recent workflow runs per phase and model (/wf cost [N]). Invoked only by typing /wf (model invocation is off).
model: sonnet
effort: high
disable-model-invocation: true
argument-hint: "<task> | cost [N]"
---

# wf (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/core-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/core-ai-skills/wf main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/core-ai-skills/wf/SKILL.md` in full, plus any file in that directory it tells
   you to read (paths in the core are relative to the core directory). If the core
   is missing, stop and tell the user the skills repo is not at that path. Do not
   improvise the skill from memory.
3. Wherever the core uses a double-brace placeholder, substitute its value from
   the tables below. If the core uses a placeholder with no row here, this
   handler is out of date: stop and name the missing variable.
4. Run every shell command for this skill from `WORKDIR`, using absolute paths,
   and write outputs under `OUTPUT_DIR` unless the core says otherwise.
5. Resolve secrets only as described under "Secrets" below, and never print them.
6. When the core tells you to spawn subagents, pick the tier for each one's job from
   `AGENT_SELECTION_FILE` and pass that tier's model and effort. `SUBAGENT_MODEL` below
   is the executor tier; a row for a specific role (such as `SUBAGENT_TYPE` or a
   `*_SUBAGENT_MODEL`) overrides the tier for that role. Never let a subagent inherit
   this skill's model unless the core says to.
7. Follow the core's instructions from there.

## Local variables

| Variable | Value | Purpose |
|---|---|---|
| `SKILL_NAME` | `wf` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/core-ai-skills/wf` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/core-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `sonnet` | Model for this skill (same as frontmatter) |
| `EFFORT` | `high` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `sonnet` | Model passed to subagents this skill spawns, as the subagent tool accepts it |
| `AGENT_SELECTION_FILE` | `/Users/davidsugianto/Artifacts/labs/src/dotfiles-macos/agent/agent-selection.md` | Model and effort for the planner, executor and scanner tiers |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/wf` | Unused by the core; the answer is the reply in chat |
| `PROJECTS_DIRS` | `/Users/davidsugianto/.claude/projects` | Space-separated Claude Code projects folders that hold workflow run journals |
| `MAX_AGENTS` | `10` | Agent count to stay under per workflow |
| `SCAN_MODEL` | `sonnet` | Model for scan, search, list and fetch stages |
| `SCAN_EFFORT` | `xhigh` | Effort for scan, search, list and fetch stages |
| `VERIFY_MODEL` | `sonnet` | Model for verify, judge, edit and write stages |
| `PROTECTED_SYSTEMS` | production Kubernetes clusters and their workloads; production databases and datastores; production cloud accounts (AWS/GCP IAM, networking, infrastructure); Datadog monitors, dashboards and log pipelines; Cloudflare DNS, WAF and zone settings; GitHub default branches, releases and repository settings; posting or editing in Slack and Jira | Systems no agent may change without the user's explicit approval for that exact change |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own |
