---
name: personal-skill-generator
description: Create, update, migrate, audit, or onboard personal agent skills using a two-part layout - a thin machine-local handler in the skills directory holding this computer's variables (working directory, model, effort, MCP server names, secret references), and a portable core in the personal skills repo holding the general function. Builds on a skill-creator tool and delegates its test-and-iterate loop to it. Use whenever the user wants to create a new skill, make or build a skill, turn a workflow or conversation into a skill, add a skill for some task, change the model, effort, or working directory of an existing skill, move a single-file skill into the handler and core layout, check that skills are consistent, or set up handlers for the skill repos on a new computer - even if they just say "make this a skill" without naming this one.
model: sonnet
effort: high
---

# personal-skill-generator (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/SKILL.md` in full, plus any file in that directory it tells
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
| `SKILL_NAME` | `personal-skill-generator` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `sonnet` | Model for this skill (same as frontmatter) |
| `EFFORT` | `high` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `sonnet` | Model passed to subagents this skill spawns, as the subagent tool accepts it |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/personal-skill-generator` | Where this skill writes its outputs |
| `REPO_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills` | Root of the default skills repo: holds this generator and any skill whose subject has no route |
| `REPO_ROUTES` | `reliability, operations, kubernetes, observability, incident response, tooling = /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills` | Routing from a skill's subject to the repo holding its core, as `subject = repo path` entries |
| `SKILLS_DIR` | `/Users/davidsugianto/.agents/skills` | Directory the agent runtime reads personal skills from |
| `DEFAULT_MODEL` | `sonnet` | Model ID given to a new skill when the user names none |
| `DEFAULT_EFFORT` | `high` | Effort level given to a new skill when the user names none |
| `DEFAULT_SUBAGENT_MODEL` | `sonnet` | Subagent model given to a new skill when the user names none, in the form the runtime's subagent tool accepts |
| `DEFAULT_WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working directory given to a new skill when the user names none |
| `MODEL_ALIASES` | `sonnet = sonnet; opus = opus; haiku = haiku` | Mapping from spoken model names to model IDs |
| `WORKSPACES_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/.workspaces` | Scratch area for test runs, outside the skills directory and git-ignored |
| `SKILL_CREATOR` | `skill-creator (the installed skill)` | Name of the installed skill-creator to delegate testing to. Skill name is the part before the parenthesis |
| `SKILL_CREATOR_DIR` | `/Users/davidsugianto/.agents/skills/skill-creator` | Where skill-creator's scripts and eval viewer live |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own; Datadog access uses the MCP server's browser OAuth session |
