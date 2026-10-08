---
name: datadog-investigate
description: Investigate a production alert, monitor, incident, or symptom the way Datadog's Bits AI SRE does - hypothesis-driven root cause analysis using the Datadog MCP as the only evidence source. Takes one or more Datadog alarm links (monitor, event, incident, trace, log, dashboard, synthetic URLs) pasted on their own, parses them, and investigates autonomously with no further questions. Builds a hypothesis tree, tests each branch with targeted logs/metrics/traces/events/change queries, prunes what the data rejects, recurses into what it supports, and reports validated / invalidated / inconclusive with the queries as evidence. Use whenever the user pastes a datadoghq.com link (even with no other text), or gives a monitor name or ID, an alert, an incident, an error spike, latency regression, "why is X failing/slow/down", "what changed", "investigate this alert", "RCA", or "bits investigate" - even if they do not mention Datadog. Prefer it for an alert, a Datadog link, or a symptom with no named cluster workload; a named failing pod, deployment, or namespace fits the cluster triage skill, and a declared incident, SEV, outage, or customer impact goes to the incident coordination skill, which calls this one. Runs a normal investigation by default; runs a deep investigation (more hypotheses, more rounds, dependency walks, disconfirmation checks) when the user asks for "deep", "deep dive", "thorough", "full RCA", or "dig deeper".
model: anthropic/claude-sonnet-5-5
effort: high
---

# datadog-investigate (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/datadog-investigate main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/datadog-investigate/SKILL.md` in full, plus any file in that directory it tells
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
| `SKILL_NAME` | `datadog-investigate` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/datadog-investigate` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `anthropic/claude-sonnet-5-5` | Model for this skill (same as frontmatter) |
| `EFFORT` | `high` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `anthropic/claude-sonnet-5` | Model passed to subagents this skill spawns, as the subagent tool accepts it |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/datadog-investigate` | Where this skill writes its outputs |
| `SUBAGENT_TYPE` | `task in omp; general-purpose in pi` | Subagent type used for executors; it must have the Datadog MCP tools |
| `MAX_EXECUTORS_PER_ROUND` | `4` | Most executors to run in parallel in one round |
| `MAX_ROUNDS` | `3` | Most plan-execute-consolidate rounds before concluding |
| `PROBE_QUERY_LIMIT` | `10` | Most queries one probe may spend in a normal run |
| `DEEP_SUBAGENT_MODEL` | `anthropic/claude-opus-5` | Model every executor runs on in a deep run |
| `DEEP_MAX_EXECUTORS_PER_ROUND` | `6` | Most executors in parallel in one round of a deep run |
| `DEEP_MAX_ROUNDS` | `5` | Most rounds in a deep run |
| `DEEP_PROBE_QUERY_LIMIT` | `25` | Most queries one probe may spend in a deep run |
| `DATADOG_MCP_PREFIX` | `omp: mcp__datadog_ (tools at xd://mcp__datadog_<tool>); pi: datadog_ (call through the mcp proxy tool, e.g. mcp({tool:"datadog_<tool>"}))` | Prefix of the Datadog MCP's tool names in this runtime |
| `DATADOG_SITE` | `us5.datadoghq.com` | Datadog site the connected MCP serves |
| `DOCS_DIR` | `none (no platform docs repo configured; skill must ask the user for one before concluding "no data")` | Documentation repo for the platform under investigation; read it before concluding a metric, log, or service has no data |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own; Datadog access uses the MCP server's browser OAuth session |
