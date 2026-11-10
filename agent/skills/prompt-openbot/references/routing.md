# Routing

Pick by the main deliverable, not by keywords. The roster in the kit's `bots/*.yaml` is the source of truth: if this table names an id the roster lacks, or disagrees with a bot's persona or guardrails, follow the roster.

| Deliverable | Bot id | Limits to remember |
|---|---|---|
| Requirements, PRD, user stories, acceptance criteria, backlog items | `product-manager` | Writes documents and ticket drafts only. Creates or edits Jira issues only if the brief says so. |
| System design, trade-offs, platform boundaries, ADR | `principal-architect` | Writes docs, ADRs and specs only. Never changes code or infrastructure. |
| API, service, webhook, MCP server, backend tests | `backend-engineer` | Migrations only against local or sandbox databases. |
| Schema, migration, SQL or index tuning, Kafka or Redis pipeline | `data-engineer` | Local or sandbox databases only. Every migration ships with a rollback. |
| UI, components, design system | `frontend-engineer` | Never publishes packages or deploys. |
| Terraform, Kubernetes, Helm, networking, IAM as code | `cloud-infrastructure-engineer` | Runs fmt, validate, plan and dry runs only. A person applies. |
| CI/CD pipelines, container builds, dashboards and alerts as code | `devops-engineer` | Delivers as a pull request. Never triggers deployments or releases. |
| Test strategy, test automation, code review, flaky tests | `qa-engineer` | Never weakens or skips tests to pass a build. |
| Security scan, threat model, secrets, IaC or dependency review | `it-security` | Report only, read-only. Drafted rules go in the report. Never alters IAM. |
| README, guides, API docs, changelog | `technical-writer` | Writes documentation files only. |
| Release notes, rollout and rollback plan, release checklist | `release-manager` | Never tags, publishes, deploys or merges. |
| Alert triage, incident coordination, SLOs, runbooks, postmortems | `sre` | Queries read-only. Proposes mitigations; never restarts, scales or rolls back. |
| Cloud or tooling cost, billing, right-sizing, commitments | `cloud-finops` | Never resizes, stops, deletes or purchases. Delivers evidence. |

## Close calls

- A cost or usage question about an observability vendor: `cloud-finops` when the deliverable is the cost analysis and savings; `sre` when it is about the incident or alert behind the spend.
- A change that touches infrastructure and CI: split by file ownership. `cloud-infrastructure-engineer` owns IaC and manifests, `devops-engineer` owns pipelines.
- A review of someone's change: `qa-engineer` for behavior and tests, plus `it-security` when it touches auth, secrets, external input, IAM or IaC, CI/CD or dependencies. These two can run in parallel on the same input.
- Planning before building: `product-manager` when the requirement is unclear, then `principal-architect` for the design.
- Docs after a verified change: `technical-writer`, then `release-manager` for notes and the rollout plan.

## Chains

Use a chain only when each stage needs the previous stage's output and the roles differ. Typical orders:

- `product-manager` then `principal-architect` then an implementer.
- An implementer then `qa-engineer` and `it-security`, then back to the implementer with the findings.
- `technical-writer` then `release-manager`.

When the request names several roles at once and the user wants the main Claude Code session to coordinate them, offer `Use openbot:team-routing.` followed by the task, in addition to or instead of the staged commands.

## No bot may

Tag, publish, deploy, merge, push, commit, apply infrastructure, restart or scale workloads, purchase commitments, or start fault-injection experiments. In Claude Code a hook blocks `git commit`, `git push`, `git merge` and `gh pr merge` for every bot. In OpenBot Desktop these limits are written instructions only, so the prompt must not ask for them either. These actions belong to the user or to the main session; give a bot the preparatory part.
