---
name: onboard-skills
description: Onboard this computer's skill handlers from the personal skill repos - pull the latest of every skill repo (such as sre-ai-skills and secops-ai-skills), check which cores already have a handler in the skills directory, and create a handler for each core that lacks one, using the standard model defaults. Use whenever the user says onboard skills, sync skills, pull the latest skills, update my skill repos, set up handlers, new skills landed, check which skills have handlers, or is on a new or freshly cloned machine - even if they only say onboarding.
model: anthropic/claude-sonnet-5-5
effort: high
---

# onboard-skills (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/onboard-skills main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/onboard-skills/SKILL.md` in full, plus any file in that directory it tells
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
| `SKILL_NAME` | `onboard-skills` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/onboard-skills` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `anthropic/claude-sonnet-5-5` | Model for this skill (same as frontmatter) |
| `EFFORT` | `high` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `anthropic/claude-sonnet-5` | Model passed to subagents this skill spawns, as the subagent tool accepts it |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/onboard-skills` | Where this skill writes its outputs |
| `SKILL_REPO_DIRS` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills` | The skill repos to sync and scan, comma-separated absolute paths |
| `SKILLS_DIR` | `/Users/davidsugianto/.agents/skills` | Directory the agent runtime reads personal skills from; handlers are written here |
| `DEFAULT_MODEL` | `anthropic/claude-sonnet-5-5` | Model ID written into a new handler's frontmatter and `MODEL` row |
| `DEFAULT_EFFORT` | `high` | Effort written into a new handler's frontmatter and `EFFORT` row |
| `DEFAULT_SUBAGENT_MODEL` | `anthropic/claude-sonnet-5` | Subagent model written into a new handler's `SUBAGENT_MODEL` row, in the form the subagent tool accepts |
| `DEFAULT_WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working and output directory written into a new handler when the core names no other |
| `GENERATOR_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator` | The generator's core directory: holds the handler template, the checker, the preflight script, and the secrets guide |
| `SUBAGENT_EFFORT` | `medium` | Effort the drafting subagents work at |
| `SUBAGENT_TYPE` | `task in omp; general-purpose in pi` | Subagent type for the drafting subagents (they need to read and write files) |
| `MAX_PARALLEL_SUBAGENTS` | `4` | Most drafting subagents to run at once |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own; Datadog access uses the MCP server's browser OAuth session |
