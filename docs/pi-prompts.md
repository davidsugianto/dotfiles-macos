# pi prompt templates, annotated

Every file in `pi/prompts/` (linked to `~/.pi/agent/prompts`) becomes a slash
command named after the file. `$@` in a template is replaced by whatever you
type after the command. The front matter's `description` and `argument-hint`
are what pi's autocomplete shows.

For the order to use them in, see [pi-workflow-guide.md](pi-workflow-guide.md).
Comments live here rather than inside the templates because pi sends a
template's whole body to the model.

| Command | File | Edits files? | Stops for you | Usual next step |
|---|---|---|---|---|
| `/plan <task>` | `plan.md` | no | plan approval | `/execute` or `/superagent` |
| `/execute <plan>` | `execute.md` | yes | missing approval or open design decision | `/review` |
| `/superagent <plan>` | `superagent.md` | yes (via workers) | slice table, blocked workers | `/review` |
| `/delegate [constraints]` | `delegate.md` | yes (via workers) | slice table, blocked workers | `/review` |
| `/review [focus]` | `review.md` | no | always | `/fix` or `/test` |
| `/fix <findings>` | `fix.md` | yes | materially different remedy | `/review` |
| `/test [scope]` | `test.md` | no | always (test gate) | `/commit` |
| `/commit [context]` | `commit.md` | only after `yes` | always (commit gate) | — |
| `/do-handoff [title]` | `do-handoff.md` | writes the handoff file | — | `/work-on-handoff` later |
| `/work-on-handoff <file>` | `work-on-handoff.md` | yes | missing file | `/handoff` to archive |

The workflow templates (`/plan`, `/execute`, `/superagent`, `/review`, `/fix`,
`/test`, `/commit`) read `~/.pi/agent/PI.md` first, so the rules there (gates,
test-first, no silent decisions, never commit without approval) apply to each.
`/delegate` follows the herdr-delegate skill; the handoff templates only read
and write handoff files.

---

## `/plan` — `plan.md`

**Use when:** starting any non-trivial task. **Argument:** the task.

| Template step | What it's for |
|---|---|
| "Planning mode only: do not edit…" | Hard read-only mode, so nothing changes before you approve |
| 1. Read PI.md, repo, docs, git status, history | Plans are built on the actual code, and your uncommitted work is noted, not overwritten |
| 2. Understanding, assumptions, success criteria; ask when trade-offs are material | Surfaces decisions to you instead of making them silently |
| 3. Smallest solution, reuse conventions, state what's out of scope | Prevents gold-plating |
| 4. 2–3 approaches only when trade-offs matter | Avoids fake choices on obvious tasks |
| 5. Files + responsibilities, ordered steps, exact validation commands, risks | The file list per step is what `/superagent` later slices on |
| 6. Planning gate | Ends waiting for your explicit OK |

**You reply:** `OK`, or the changes you want.

## `/execute` — `execute.md`

**Use when:** running an approved plan with one agent. **Argument:** the plan
or "the approved plan above".

| Template step | What it's for |
|---|---|
| "confirm the plan has explicit user approval" | Refuses to start from an unapproved plan; summarizes and stops instead |
| 1. Read PI.md, plan, files, conventions, git state | Same grounding as `/plan`; never overwrite unrelated changes |
| 2. Approved scope only; TDD for behavior changes | Failing test → confirm the failure → smallest change → rerun. Docs/config get matching validation instead |
| 3. Reuse patterns; ask on undecided design | Stops instead of improvising architecture |
| 4. Checklist; delegate only per PI.md routing, `/superagent` for approved parallel slices | Read-only lookups may go to a subagent; parallel edits go through `/superagent`, never ad hoc |
| 5. Check delegated work; targeted checks only | Full verification is left for `/test`; no commit, no "done" claim |
| Final summary → `/review` | Changed files, completed steps, remaining work, test evidence |

## `/superagent` — `superagent.md`

**Use when:** an approved plan has steps that touch different files and can
run at the same time. Must run inside Herdr. **Argument:** the plan, plus
optional overrides: a worker count ("5 workers"), a role ("worker 2 as
slow"), or a model ("workers on cekat/azure_ai/gpt-6.1-sol").

| Template step | What it's for |
|---|---|
| "You are the superagent orchestrator for: $@" | Makes this session the coordinator, not a worker |
| 1. Invoking /superagent is permission to delegate; load `herdr-delegate` + `herdr` | The skill holds the whole procedure (slicing, briefs, start, wait, verify, cleanup); the template stays short |
| 2. No approved plan in this conversation → slice table (role, resolved model, owned files, goals, validation), stop at the plan gate | You approve the split and each worker's model before any worker starts |
| 3. Run herdr-delegate end to end; do non-parallel work directly; pi slices carry a Role (`task` default, override like "worker 2 as slow") | The orchestrator also handles glue work that doesn't fit a slice; the role picks the worker model via `pi-worker-model` |
| 4. End at review hand-off, no commit | Output goes into the normal `/review` step |

**What the skill adds** (`pi/skills/herdr-delegate/SKILL.md`): 6 workers by
default (a number you name is a ceiling, capped at 12); each owns a disjoint
file set; one `sa-<id>` workspace with one tab
per worker; briefs and results as files under `$TMPDIR/superagent/<id>/`; a
screen check before prompting (for undetected dialogs); a check that only
owned files changed; re-running every validation; and closing the workspace
only if all workers finished.

**Which model a pi worker gets:** each slice has a role (`task` by default,
`slow` for hard or risky work, `smol` for trivial work). The orchestrator runs
`pi-worker-model <role>`, which reads the active `pi-roles` set
(`~/.pi/agent/extensions/pi-model-roles/config.yaml`) and prints the provider,
model and thinking effort; those are passed to `pi` as `--provider`, `--model`
and `--thinking`. A model you name in the command wins over the role. If the
role config is missing or disabled, the worker inherits `defaultModel`, and
omp workers always do. The slice table shows the resolved model, so check it
before approving. Re-run `pi-roles` after editing a role file; the helper reads
the deployed copy.

## `/delegate` — `delegate.md`

**Use when:** the work is already a list of session todos. Must run inside
Herdr. **Argument:** optional extra constraints for every worker.

| Template step | What it's for |
|---|---|
| 1. `todo list`; nothing open → "Nothing to delegate" | No empty runs |
| 2. One slice per todo (merged when they share files), labelled `todo#<id>`; constraints: `$@` | Lets you trace each worker back to its todo |
| 3. Load skills, print the slice table (pi slices carry a role and resolved model), wait for OK | Same approval point as `/superagent`; override a role with "worker 2 as slow" |
| 4. Tick a todo only after its worker reports `done` **and** verification passes; list blocked items with their questions | `/todos` never shows unverified work as done |
| 5. Review hand-off, no commit | Same as `/superagent` |

## `/review` — `review.md`

**Use when:** after `/execute`, `/superagent`, `/delegate`, or `/fix`.
**Argument:** optional focus area.

| Template step | What it's for |
|---|---|
| "Review only: do not edit…" | A review that edits is no longer a review |
| 1. Read both diffs (staged and unstaged), status, surrounding code, tests | Covers staged and unstaged work |
| 2. Correctness, regressions, errors, maintainability, coverage, plan fit | The review checklist |
| 3. Security review when the change handles secrets, auth, external requests, CI/CD | Brings in the security pass only where it matters |
| 4. Actionable findings: severity, file:line, impact, fix; blocking vs suggestions | Gives `/fix` something precise to act on |
| 5. No findings → say what was reviewed, not "done" | Review isn't verification |
| Gate | Waits for you to choose `/fix` or `/test` |

## `/fix` — `fix.md`

**Use when:** acting on review findings. **Argument:** which findings, plus
your decisions ("fix 1 and 3, skip 2").

| Template step | What it's for |
|---|---|
| 1. Read PI.md, diff, cited code/tests, findings | Grounding |
| 2. Verify each finding before changing anything; skip with a reason if wrong | Reviewers can be wrong; nothing is fixed blindly |
| 3. TDD for each behavioral fix | The fix comes with a test that failed before it |
| 4. No scope growth; ask before a materially different remedy | Keeps fixes small |
| 5. Each finding: fixed / not applicable / blocked, with evidence | Traceable outcome |
| Next | Back to `/review` if anything changed, otherwise asks about `/test` |

## `/test` — `test.md`

**Use when:** review is clean. **Argument:** optional scope or extra checks,
e.g. "include the Playwright E2E suite".

| Template step | What it's for |
|---|---|
| "Verification only…" | No edits while verifying, and no claiming success without fresh output |
| 1. Find the real commands from docs and package/build config | Uses the project's own checks, not guesses |
| 2. Tests, lint, build/types, smoke of the changed path; full suite when feasible | E2E and smoke checks live here, after all slices are combined |
| 3. Report every command's exit status and output, including skipped checks | You see the evidence directly |
| 4. On failure: systematic debugging, don't hide pre-existing failures | Root cause before a fix |
| Gate | Diff summary + fresh output, then waits before `/commit` |

## `/commit` — `commit.md`

**Use when:** tests passed and you approved the result. **Argument:** optional
context for the message.

| Template step | What it's for |
|---|---|
| "Do not commit yet." | Nothing is staged until you say yes |
| 1. Read diffs, the latest review outcome, fresh verification | Commits only reviewed, verified work |
| 2. Prerequisites: findings resolved, checks passing, no unrelated files | Missing one → it names the blocker and stops |
| 3. One imperative conventional commit message matching the diff | e.g. `feat: add health endpoint` |
| 4. Show message, exact files, diff summary, evidence | You approve exactly what gets committed |
| Gate | Only after `yes` does it stage and commit |

## `/do-handoff` — `do-handoff.md`

**Use when:** stopping before the work is finished. **Argument:** optional
title (otherwise one is derived).

| Template step | What it's for |
|---|---|
| 1. Read conversation, git status, diff, files | Captures the real state, not memory |
| 2. `~/.pi/agent/handoffs/YYYY-MM-DD-handoff-<kebab-title>.md` | Predictable name that `/handoff` lists |
| 3. Front matter `title` / `status: active` / `created` | `status` is what `/handoff` reads to archive |
| 4–5. Context, Done, Remaining, Next step, Files, Validation; real commands and blockers; no false "done" | The next session can resume without re-discovering anything |
| "Do not write inside `_archived/`" | Archived handoffs are history |

## `/work-on-handoff` — `work-on-handoff.md`

**Use when:** resuming. **Argument:** the handoff file name (`/handoff` lists
the active ones).

| Template step | What it's for |
|---|---|
| 1–2. Resolve only from `~/.pi/agent/handoffs/`; missing → list valid names | Never resumes archived or guessed files |
| 3. `status: in_progress` before any change | Shows the handoff is being worked on |
| 4–5. Do Remaining / Next step, update Done / Files / Validation, run the smallest checks | The handoff stays accurate as work proceeds |
| 6. `status: done` only when everything is finished; `/handoff` archives it | No premature archiving |

## Related non-template commands

| Command | Comes from | Does |
|---|---|---|
| `/todos` | `pi/extensions/todo.ts` | Session todo list (`↑↓`/`j k`, Space toggle, Enter detail, Esc close); the agent uses the `todo` tool |
| `/handoff [title]` | `pi/extensions/manage-handoff.ts` | No title: lists active handoffs and archives `done` ones. With a title: creates a handoff file |
| `/herdr-agents` | `pi/extensions/herdr-agent/` | One line per Herdr agent: name, kind, status, cwd |
| `/agents` | `@tintinweb/pi-subagents` | Subagent manager: running agents, conversation viewer, custom types, settings |
| `/skill:herdr-delegate`, `/skill:herdr` | `pi/skills/` (also omp via `omp/skills/`) | Load the skill by hand, e.g. in omp |

## Editing a template

- Keep the front matter `description` short: it's the autocomplete label.
- `$@` is everything typed after the command; use it once, where the task text
  belongs.
- Point to PI.md for rules instead of copying them into the template.
- Changes apply after `/reload` in open sessions (templates are read when pi
  loads its resources).
