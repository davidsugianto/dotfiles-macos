# prompt-openbot examples

Three worked examples: a pasted prompt-forge result, a rough request that needs a chain, and a request no bot may do. Paths such as `<OUTPUT_DIR>` stand for the Local values in SKILL.md.

## Example 1: A pasted prompt-forge result

**Input**

The user pastes a finished prompt (Task, Context, Requirements, Output format, Writing rules) that asks for an HTML report on why a Datadog Product Analytics bill is high. It is analysis only: read-only API calls through `curl`, then one HTML file written to `docs/`.

**Output**

**Agent:** Cloud FinOps (`openbot:cloud-finops` in Claude Code, "Cloud FinOps" in OpenBot Desktop). The deliverable is a cost analysis with savings options. `sre` is the alternative if the question were about an alert or incident behind the spend.

````
## Task
Investigate why Datadog Product Analytics cost is high, then write an HTML report ...
(... the pasted prompt, unchanged: Context, Requirements, Output format, Writing rules ...)

## Agent rules
- Work from this brief alone. Where information is missing, state an assumption in your result and continue, unless one of your guardrails tells you to stop and ask.
- Do not commit, push or merge, and change nothing outside the files this task names.
- Finish with what you did, the files you wrote with their paths, the commands you ran with their output, and open questions.
````

**Saved:** `<OUTPUT_DIR>/2026-11-10-datadog-product-analytics-cost.md`

**Run in Claude Code**
```sh
cd [WORKING_DIR]
{ echo "Delegate the brief below to the openbot:cloud-finops agent. Return its final answer unchanged."
  echo
  cat <OUTPUT_DIR>/2026-11-10-datadog-product-analytics-cost.md
} | <CLAUDE_CMD> -p \
    --permission-mode acceptEdits \
    --allowedTools "Bash(curl:*)" "Bash(jq:*)" "Read" "Write"
```

**Run in OpenBot Desktop**
```sh
<OPENBOT_CLI> run "Cloud FinOps" - --wait --timeout 30m < <OUTPUT_DIR>/2026-11-10-datadog-product-analytics-cost.md
```

**Notes**
- The pasted prompt was kept word for word; only the Agent rules block was added.
- `[WORKING_DIR]`: the repo whose `docs/` folder receives the report.
- Flags: `Bash(curl:*)` and `Bash(jq:*)` for the API calls the prompt names, `Write` with `acceptEdits` for the one HTML file. Nothing else is allowed.
- The prompt reads credentials from environment variables; start the command from a shell that has them.

Why: the deliverable is cost analysis, so one bot is enough. The flags match the commands and the write the prompt names, no more.

## Example 2: A rough request that needs a chain

**Input**

```
tambahin kolom archived_at di tabel orders (nullable), bikin migration-nya, terus minta qa review
```

**Output**

**Agent:** Data Engineer (`openbot:data-engineer`), then QA Engineer (`openbot:qa-engineer`). The migration is data-engineer's work; the review needs a different role and the migration's output, so it is a two-stage chain.

Stage 1 prompt:

```
## Task
Add a nullable `archived_at timestamptz` column to the `orders` table and write the migration, with a rollback.

## Context
- Migrations live in `[MIGRATIONS_DIR]`; the migration tool is `[MIGRATION_TOOL]`.
- Run migrations only against the local database.

## Requirements
- Write an up and a down migration. The down migration drops the column.
- Estimate lock time and table size impact for `[DB_ENGINE]` and say how you estimated it.
- Run the migration up and down on the local database and show the output.
- Do not backfill the column.

## Output format
List the files changed, the commands you ran with their output, the lock-time estimate, and open questions.

## Agent rules
- Work from this brief alone. Where information is missing, state an assumption in your result and continue, unless one of your guardrails tells you to stop and ask.
- Do not commit, push or merge, and change nothing outside the files this task names.
- Finish with what you did, the files you wrote with their paths, the commands you ran with their output, and open questions.
```

Stage 2 prompt:

```
## Task
Review the migration described under "Output of the previous stage" for correctness, rollback safety and test coverage.

## Requirements
- Report each problem with a reproduction step, the expected result and the actual result.
- Say whether the rollback restores the previous schema.
- Do not change files.

## Agent rules
- Work from this brief alone. Where information is missing, state an assumption in your result and continue, unless one of your guardrails tells you to stop and ask.
- Do not commit, push or merge, and change nothing outside the files this task names.
- Finish with what you did, the commands you ran with their output, and open questions.
```

**Saved:** `<OUTPUT_DIR>/2026-11-10-archived-at-orders-1-data-engineer.md`, `<OUTPUT_DIR>/2026-11-10-archived-at-orders-2-qa-engineer.md`

**Run in Claude Code**
```sh
set -e
cd [WORKING_DIR]
{ echo "Delegate the brief below to the openbot:data-engineer agent. Return its final answer unchanged."; echo; cat <OUTPUT_DIR>/2026-11-10-archived-at-orders-1-data-engineer.md; } \
  | <CLAUDE_CMD> -p --permission-mode acceptEdits --allowedTools "Read" "Write" "Edit" "Bash(make:*)" \
  > <OUTPUT_DIR>/2026-11-10-archived-at-orders-1-data-engineer.out.md
{ echo "Delegate the brief below to the openbot:qa-engineer agent. Return its final answer unchanged."; echo; cat <OUTPUT_DIR>/2026-11-10-archived-at-orders-2-qa-engineer.md; echo; echo "Output of the previous stage:"; cat <OUTPUT_DIR>/2026-11-10-archived-at-orders-1-data-engineer.out.md; } \
  | <CLAUDE_CMD> -p --allowedTools "Read"
```

**Run in OpenBot Desktop**
```sh
set -e
<OPENBOT_CLI> run "Data Engineer" - --wait --timeout 30m < <OUTPUT_DIR>/2026-11-10-archived-at-orders-1-data-engineer.md > <OUTPUT_DIR>/2026-11-10-archived-at-orders-1-data-engineer.out.md
{ cat <OUTPUT_DIR>/2026-11-10-archived-at-orders-2-qa-engineer.md; echo; echo "Output of the previous stage:"; cat <OUTPUT_DIR>/2026-11-10-archived-at-orders-1-data-engineer.out.md; } \
  | <OPENBOT_CLI> run "QA Engineer" - --wait --timeout 30m
```

**Notes**
- Placeholders to fill in the stage 1 file before running: `[MIGRATIONS_DIR]`, `[MIGRATION_TOOL]`, `[DB_ENGINE]`, and `[WORKING_DIR]` in the commands.
- Assumption: no backfill, because you did not ask for one.
- Stage 1 gets `Write`, `Edit` and `Bash(make:*)` because it writes migration files and runs them. If the migration tool is not run through make, change the Bash pattern to that tool.
- Stage 2 gets `Read` only: the review does not change files.
- Instead of two stages, `Use openbot:team-routing.` followed by the task lets the main Claude Code session do the chaining.

Why: a chain is justified because the second role needs the first one's output. The staged flags give each stage only what it uses.

## Example 3: A request no bot may do

**Input**

```
tag v1.4.0 terus publish ke npm
```

**Output**

No bot can run this. Tagging and publishing are barred for every bot: `release-manager` is told never to tag or publish and has `git tag` and `npm publish` on its deny list, and in Claude Code a hook blocks commits, pushes and merges for all of them. Do these two steps yourself, or ask the main session.

The part a bot can prepare is the release notes and the rollout and rollback plan. Prompt for `release-manager`:

```
## Task
Prepare the release of version `[VERSION]` of `[PROJECT]`: release notes, a pre-release checklist and a rollout and rollback plan.

## Context
- Merged work since the last release is in `[PREVIOUS_TAG]..HEAD`.

## Requirements
- Release notes grouped by user-visible change, from the merged commits and pull requests.
- Check the version in `[VERSION_FILES]` and the CI status, and list anything that blocks the release.
- For each risk, give the rollback step and the signal that triggers it.
- Do not tag, publish, deploy or merge. A person cuts the release.

## Output format
Return the release notes, the checklist and the plan as Markdown in your reply.

## Agent rules
- Work from this brief alone. Where information is missing, state an assumption in your result and continue, unless one of your guardrails tells you to stop and ask.
- Do not commit, push or merge, and change nothing outside the files this task names.
- Finish with what you did, the files you wrote with their paths, the commands you ran with their output, and open questions.
```

**Saved:** `<OUTPUT_DIR>/2026-11-10-release-notes-and-plan.md`

**Run in Claude Code**
```sh
cd [WORKING_DIR]
{ echo "Delegate the brief below to the openbot:release-manager agent. Return its final answer unchanged."
  echo
  cat <OUTPUT_DIR>/2026-11-10-release-notes-and-plan.md
} | <CLAUDE_CMD> -p --allowedTools "Read" "Bash(git log:*)" "Bash(gh pr list:*)"
```

**Run in OpenBot Desktop**
```sh
<OPENBOT_CLI> run "Release Manager" - --wait --timeout 30m < <OUTPUT_DIR>/2026-11-10-release-notes-and-plan.md
```

**Notes**
- Removed from the request: tagging `v1.4.0` and publishing to npm. You do these after reading the plan.
- Placeholders to fill in the file: `[VERSION]`, `[PROJECT]`, `[PREVIOUS_TAG]`, `[VERSION_FILES]`, and `[WORKING_DIR]` in the commands.
- The release notes come back in the reply and are not written to a file, so the flags allow no writes.

Why: a bot that is told never to tag or publish cannot do the request, so the skill says that first, then prepares what a bot can do.
