---
name: investigation-report
description: Write the finished HTML report document for an investigation, triage, Kubernetes cost review, or incident postmortem - one self-contained, escaped, dark-mode-aware page saved to disk with a dated title and file name, in the report format (profile) the calling skill names. Use whenever a skill or the user needs the report for a completed root-cause investigation (hypothesis tree, evidence, final root cause), a completed workload triage, a completed cost review (prioritized changes, marginal savings, evidence), or a completed incident postmortem (timeline, impact, root cause, action items), or says "write the report", "make an HTML report", "save this investigation as a document", "report for the triage", "cost review report", "postmortem report", or "document what we found" - even if they do not say HTML. Owns the page rules, the title and file name rules, the output folder, and the checks after writing. The producing skill owns the findings.
model: anthropic/claude-sonnet-5-5
effort: high
---

# investigation-report (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/investigation-report main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/investigation-report/SKILL.md` in full, plus any file in that directory it tells
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
| `SKILL_NAME` | `investigation-report` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/investigation-report` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `anthropic/claude-sonnet-5-5` | Model for this skill (same as frontmatter) |
| `EFFORT` | `high` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `anthropic/claude-sonnet-5` | Model passed to subagents this skill spawns, as the subagent tool accepts it |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/investigation-report` | Where this skill writes its outputs |
| `PAGE_DESIGN_SKILL` | `frontend-engineer` | Skill that governs the page contract for HTML output |
| `CHART_SKILL` | `frontend-engineer` | Skill that governs charts, loaded before drawing any chart |
| `INVESTIGATION_OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/investigations` | Fallback folder for investigation reports when a caller supplies a cost-review destination |
| `OPEN_COMMAND` | `open` | Command that opens a file for viewing on this machine |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own; Datadog access uses the MCP server's browser OAuth session |
