---
name: k8s-triage
description: Triage a failing, crash-looping, pending, slow, or unreachable Kubernetes workload read-only - events, logs, owner chain, and a likely cause - and, when the image has no shell or the cause is only visible from inside the pod, take a live look with a correctly profiled ephemeral debug container (kubectl debug), including datastores such as Redis/Valkey and RabbitMQ. Use whenever the user names a pod, deployment, statefulset, namespace, or service that is failing, restarting, OOMKilled, stuck Pending, ImagePullBackOff, CrashLoopBackOff, not ready, returning 5xx, or "why is X down in the cluster", says "triage", "debug this pod", "kubectl debug", or "exec into" a distroless container, or asks to check a queue or cache from inside the cluster - even if they do not say Kubernetes. Prefer it when a specific cluster workload is named. An alert or Datadog link with no named workload fits the telemetry investigation skill, and a declared incident goes to the incident coordination skill.
model: sonnet
effort: high
---

# k8s-triage (local handler)

This is the machine-local half of the skill. It holds values that belong to this
computer and this agent setup. The general instructions live in the shared core.

## How to run

1. **Preflight, before anything else.** Run
   `bash /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh /Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/k8s-triage main origin` (the values of `PREFLIGHT_SCRIPT`,
   `CORE_DIR`, `CORE_BRANCH`, `CORE_REMOTE` below). If it prints `PREFLIGHT: ok`,
   continue. If it prints `PREFLIGHT: pause`, or the script is missing or fails to
   run, **stop**: do not read the core and do not run the skill. Say so in the
   first lines of your reply: which skill, what the script found, and the fix
   commands it printed. If a notification tool is available, also send one short
   notification so the user sees it when away. Run no git command that changes
   the checkout (no switch, pull, stash, or reset); fixing it is the user's call.
   Then wait. If the user answers "proceed anyway", continue for this run only
   and say in your final answer that the core was not verified current.
2. Read `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/k8s-triage/SKILL.md` in full, plus any file in that directory it tells
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
| `SKILL_NAME` | `k8s-triage` | This skill's name |
| `CORE_DIR` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/k8s-triage` | Where the portable core lives |
| `CORE_BRANCH` | `main` | Branch the core's repo must be on |
| `CORE_REMOTE` | `origin` | Remote the core's branch must be up to date with |
| `PREFLIGHT_SCRIPT` | `/Users/davidsugianto/Artifacts/labs/src/sre-ai-skills/personal-skill-generator/scripts/preflight.sh` | Script that checks branch and freshness before every run |
| `MODEL` | `sonnet` | Model for this skill (same as frontmatter) |
| `EFFORT` | `high` | Effort for this skill (same as frontmatter) |
| `SUBAGENT_MODEL` | `sonnet` | Model passed to subagents this skill spawns, as the subagent tool accepts it |
| `WORKDIR` | `/Users/davidsugianto/Artifacts/labs` | Working directory for this skill's commands |
| `OUTPUT_DIR` | `/Users/davidsugianto/Artifacts/labs/tmp/sre-reports/k8s-triage` | Where this skill writes its outputs |
| `DEBUG_ALLOWED_CONTEXTS` | `none (always ask before creating a debug container)` | kubectl contexts where this skill may create debug containers without asking first |
| `DEBUG_IMAGE` | `busybox:1.36.1` | Image for debug containers (needs `sh`, `nc`, `wget`, `nslookup`, `ps`) |
| `DEBUG_SLEEP_SECONDS` | `600` | How long a debug container sleeps before it exits on its own |
| `LOG_BILLING_PROJECT` | `none` | Project to bill cloud log reads to when the cluster's own project has the logging API disabled; `none` if not needed |

## Secrets

References only. Resolve a secret inside the same command that uses it, pass it
through the environment or stdin, and never echo, log, or save it. See the core
generator's secrets guide for the patterns.

| Name | Reference | Used for |
|---|---|---|
| none | n/a | Skill needs no credentials of its own; Datadog access uses the MCP server's browser OAuth session |
