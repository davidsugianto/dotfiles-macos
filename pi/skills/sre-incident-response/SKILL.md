---
name: sre-incident-response
description: Coordinate a live production incident and write its postmortem, in three modes: new (open an incident), continue (pick up an incident that already has a log, in a new session or after a break, or take over one that another agent posted in Slack from the link to its thread), and postmortem (write up an incident that is resolved or closed). As incident coordinator it opens a timestamped incident log, proposes a severity, routes the analysis to whichever investigation skills fit what it was given (the roster of investigators is configured outside the skill, and the user can name any investigation skill for a run), keeps a running state of impact, hypothesis and actions, drafts status updates, and recommends only reversible mitigations without ever applying them. At every close, resolved or not, it turns the log and the investigators' final root causes into a blameless postmortem HTML report through the report skill. Use whenever the user says "we have an incident", "production is down", "declare an incident", "SEV1", "SEV2", "outage", "run this incident", "keep the timeline", "draft a status update", "continue the incident", "resume the incident", "pick up where we left off", "take over this incident" with a Slack thread link, "it is over", "write the postmortem", "post-incident review", "postmortem for the closed incident", "incident report", or "RCA document for the incident", or pastes an alert link and says it is customer-impacting - even if they do not say incident. Prefer it over the individual investigation skills whenever an incident, SEV, outage, or customer impact is declared, then call them; a bare alert link, symptom, or failing workload with no incident declared goes to those skills directly.
model: anthropic/claude-sonnet-5-5
effort: high
---

# sre-incident-response (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/sre-incident-response main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/sre-incident-response/SKILL.md` in full, plus any file in that directory it tells
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
| `SKILL_NAME` | `sre-incident-response` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/sre-incident-response` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `anthropic/claude-sonnet-5-5` | Model for this skill (same as frontmatter) |
| `EFFORT` | `high` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `anthropic/claude-sonnet-5` | Model for subagents this skill spawns for clerical work |
| `SUBAGENT_TYPE` | `task in omp; general-purpose in pi` | Subagent type for investigators and the watch |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/sre-incident-response` | Where this skill writes its outputs |
| `LOG_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/sre-incident-response/logs` | Folder holding one working incident log (Markdown) per incident |
| `PARALLEL_INVESTIGATORS` | `yes` | Start matching investigators at once as background subagents |
| `INVESTIGATOR_SUBAGENT_MODEL` | `anthropic/claude-sonnet-5` | Matches the investigators' own model |
| `INVESTIGATORS` | see the Investigators table below | Roster of investigation skills |
| `REPORT_SKILL` | `investigation-report` | Skill that writes the HTML report document from finished findings |
| `UPDATE_INTERVAL_MINUTES` | `15` | How often a status update is due while an incident is open |
| `SLACK_CHANNEL` | `` (unset) | Channel id for the incident summary post; empty means do not post. Scope value, set by the person only |
| `SLACK_POST_TOOL` | `slack_send_message` (pi: through the mcp proxy tool; omp: `mcp__slack_send_message`) | Posts a message to a channel |
| `SLACK_UPLOAD_TOOLS` | `slack_get_file_upload_url`, then `slack_complete_file_upload` (same access as the post tool) | Uploads a file to a channel |
| `SLACK_READ_TOOLS` | `slack_read_thread`, `slack_read_canvas`, `slack_read_file` (same access as the post tool) | Reads a thread, a canvas and an attached file |
| `SLACK_CANVAS_TOOL` | `slack_update_canvas` (same access as the post tool) | Edits a canvas |
| `SLACK_CANVAS_ID` | `` (unset) | Channel canvas the watch reads and edits; empty means no canvas |
| `SLACK_CANVAS_ROW` | `` (unset) | Slack user id of the canvas row the coordinator may edit. Scope value, set by the person only |
| `SLACK_REACT_TOOL` | `slack_add_reaction` (same access as the post tool) | Adds a reaction to a message |
| `CLOSED_REACTION` | `white_check_mark` | Reaction added to the incident post at close |
| `HUMANIZER_SKILL` | `none` | No humanizer skill installed on this machine |
| `SCHEDULER_TOOLS` | none | Schedules and deletes a recurring session job |
| `WATCH_INTERVAL_MINUTES` | `5` | How often the thread watch checks Slack |
| `WATCH_SUBAGENT_MODEL` | `anthropic/claude-sonnet-5` | Model for the read-only watch subagent |
| `GATE_NOTICE_MINUTES` | `10` | How long an updated analysis may wait on another agent before the commander is told |
| `GATE_CLAIM_WAIT_SECONDS` | `30` | Wait after claiming the canvas before checking for a simultaneous claim |

## Investigators

The roster for `INVESTIGATORS`. Adding a row adds an investigator.

| Skill | Use when given | Runs | Why |
|---|---|---|---|
| `datadog-investigate` | a Datadog alert, monitor, incident or trace link, or a symptom with no named workload | as a subagent | telemetry-based root cause analysis |
| `k8s-triage` | a named failing pod, deployment or namespace | as a subagent | cluster-level triage |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own; Datadog access uses the MCP server's browser OAuth session |
