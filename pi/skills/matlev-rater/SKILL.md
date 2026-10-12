---
name: matlev-rater
description: Rate the maturity level (MatLev, ML0 to ML4) of an organisation's infrastructure capabilities by fanning out read-only evidence-gathering subagents - one per platform repository, one for the live Kubernetes clusters (kubectl), one for Datadog (MCP), one for Cloudflare (MCP) - then consolidating their evidence into a scorecard with Now, Next, and North per capability and a written report. Use whenever the user asks to rate, score, assess, re-rate, or update the MatLev or maturity level of the infrastructure or platform, to confirm the scorecard live, to find which capabilities are ML1/ML2/ML3, "how mature is our infrastructure", "run the maturity assessment", "check the scorecard against reality", or to refresh the maturity handbook - even if they do not say MatLev.
model: anthropic/claude-sonnet-5-5
effort: high
---

# matlev-rater (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/matlev-rater main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/matlev-rater/SKILL.md` in full, plus any file in that directory it tells
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
| `SKILL_NAME` | `matlev-rater` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/matlev-rater` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `anthropic/claude-sonnet-5-5` | Model for this skill (same as frontmatter) |
| `EFFORT` | `high` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `anthropic/claude-sonnet-5` | Model passed to subagents this skill spawns, as the subagent tool accepts it |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/matlev-rater` | Where this skill writes its outputs |
| `SUBAGENT_EFFORT` | `high` | Reasoning effort every assessor is asked to use |
| `SUBAGENT_TYPE` | `task in omp; general-purpose in pi` | Subagent type for assessors, when the runtime has a dedicated one |
| `FALLBACK_SUBAGENT_TYPE` | `task in omp; general-purpose in pi` | Subagent type to use when `{{SUBAGENT_TYPE}}` is not available in this session |
| `MAX_ROUNDS` | `2` | Most dispatch rounds (first round plus targeted follow-ups) before concluding |
| `DATADOG_MCP_PREFIX` | `omp: mcp__datadog_ (tools at xd://mcp__datadog_<tool>); pi: datadog_ (call through the mcp proxy tool, e.g. mcp({tool:"datadog_<tool>"}))` | Prefix of the Datadog MCP's tool names in this runtime |
| `DATADOG_SITE` | `us5.datadoghq.com` | Datadog site the connected MCP serves |
| `CLOUDFLARE_MCP_PREFIX` | `none (no Cloudflare MCP configured in omp/mcp.json or pi/mcp-adapter.json)` | Prefix of the Cloudflare MCP's tool names in this runtime |
| `SCALE_DOC` | `UNSET` | The document that defines ML0 to ML4, the rating method, and the current scorecard UNSET: stop and tell the user to fill this row in this handler before any assessment; never infer it. |
| `REPOS_ROOT` | `UNSET` | Folder that holds the platform repositories UNSET: stop and tell the user to fill this row in this handler before any assessment; never infer it. |
| `PLATFORM_REPOS` | `UNSET` | The repositories to assess, one assessor each UNSET: stop and tell the user to fill this row in this handler before any assessment; never infer it. |
| `KUBE_CONTEXTS` | `UNSET` | kubectl contexts of the live clusters in scope UNSET: stop and tell the user to fill this row in this handler before any assessment; never infer it. |
| `KUBE_CONTEXTS_EXCLUDED` | `UNSET` | kubectl contexts that exist but are out of scope UNSET: stop and tell the user to fill this row in this handler before any assessment; never infer it. |
| `KUBE_ALLOWED_VERBS` | `UNSET` | The only kubectl verbs an assessor may run UNSET: stop and tell the user to fill this row in this handler before any assessment; never infer it. |
| `IN_SCOPE_DOMAINS` | `UNSET` | The only DNS zones the Cloudflare assessor may read UNSET: stop and tell the user to fill this row in this handler before any assessment; never infer it. |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own; Datadog access uses the MCP server's browser OAuth session |
