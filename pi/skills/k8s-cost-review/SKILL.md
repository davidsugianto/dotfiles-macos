---
name: k8s-cost-review
description: Analyze Kubernetes clusters read-only to find actionable cost savings, using live capacity and scheduling evidence, historical workload utilization, autoscaling settings, storage and network inventory, and cloud pricing or billing when available. Produce a prioritized savings plan with concrete changes, dependencies, reliability constraints, and defensible estimates. Use whenever the user asks to reduce a Kubernetes or GKE/EKS/AKS bill, find cluster waste, rightsize pods or nodes, identify idle capacity, review Spot or commitment opportunities, optimize cluster spend, or find what needs to be done for cost saving in a k8s cluster, even if they do not name this skill.
model: anthropic/claude-sonnet-5-5
effort: high
---

# k8s-cost-review (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/k8s-cost-review main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/k8s-cost-review/SKILL.md` in full, plus any file in that directory it tells
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
| `SKILL_NAME` | `k8s-cost-review` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/k8s-cost-review` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `anthropic/claude-sonnet-5-5` | Model for this skill (same as frontmatter) |
| `EFFORT` | `high` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `anthropic/claude-sonnet-5` | Model passed to subagents this skill spawns, as the subagent tool accepts it |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/k8s-cost-review` | Where this skill writes its outputs |
| `HTML_OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/k8s-cost-review/html` | Private local destination for finished HTML reports |
| `REPORT_SKILL` | `investigation-report` | HTML report writer with the cost-review profile |
| `PAGE_DESIGN_SKILL` | `frontend-engineer` | Page-design skill passed to the HTML writer |
| `SUBAGENT_TYPE` | `task in omp; general-purpose in pi` | Evidence-collector agent type |
| `SUBAGENT_EFFORT` | `high` | Reasoning effort requested in collector briefs |
| `MAX_PARALLEL_AGENTS` | `4` | Maximum simultaneous collectors |
| `MAX_ROUNDS` | `2` | Maximum evidence-dispatch rounds, including follow-ups |
| `LOOKBACK_DAYS` | `14` | Default historical utilization window |
| `MONTH_HOURS` | `730` | Hours used for labeled monthly run-rate estimates |
| `KUBE_CONTEXTS` | `none preset: use only contexts named in the request; if none named, show kubectl config get-contexts and ask` | Optional default contexts, or a current-context discovery policy |
| `SOURCE_REPOS` | `none` | Optional local desired-state repositories, or none |
| `METRICS_MCP_PREFIX` | `omp: mcp__datadog_ (tools at xd://mcp__datadog_<tool>); pi: datadog_ (call through the mcp proxy tool, e.g. mcp({tool:"datadog_<tool>"}))` | Optional metrics connector namespace/tool prefix |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own; Datadog access uses the MCP server's browser OAuth session |
