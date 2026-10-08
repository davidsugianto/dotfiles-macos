---
name: jira-space-keeper
description: Record findings and tasks into a Jira space of the user's choosing so every colleague and agent files them the same way - dedupe against what is filed, show one preview, write only after approval, list open items for triage, assign, transition or link on request, and maintain the space's shared board profile (conventions pinned inside the space). Guides installing and signing in to a Jira MCP server and checks access on first contact with a new site or space. Use whenever a user or agent wants to file, log, record, ticket, or "put on the board" a finding, follow-up, action item, or task; turn findings from an SRE investigation, postmortem, audit, or review into Jira issues for triage; check whether something is already filed; see what is open or untriaged in a space; assign, move, or link Jira issues; or set up how a Jira space or board is used - even if they only say "ticket", "Jira", "board", "backlog", or "space".
model: sonnet
effort: medium
---

# jira-space-keeper (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/jira-space-keeper main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/jira-space-keeper/SKILL.md` in full, plus any file in that directory it tells
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
7. Follow the core's instructions from there.

## Local variables

| Variable | Value | Purpose |
|---|---|---|
| `SKILL_NAME` | `jira-space-keeper` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/jira-space-keeper` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `sonnet` | Model for this skill (same as frontmatter) |
| `EFFORT` | `medium` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `sonnet` | Model passed to subagents this skill spawns, as the subagent tool accepts it |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/jira-space-keeper` | Where this skill writes its outputs |
| `JIRA_MCP_SERVER` | `jira (tools are mcp__jira__<tool>)` | Preferred MCP server for Jira tools, and the name to use when installing one |
| `JIRA_SITE` | `unset` | Default Atlassian site host; unset means discover it with getAccessibleAtlassianResources |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own; Jira access uses the MCP server's OAuth session |
