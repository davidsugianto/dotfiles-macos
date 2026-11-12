---
name: herdr-delegate
description: "Delegate work to registered claude/pi/omp worker agents in a dedicated Herdr workspace (one tab per worker) or, in the Herdr desktop app, as labelled hc terminals, with disjoint file ownership, file-based briefs and results, and verified integration. Use only when the user explicitly asks to delegate/spawn/parallelize, or when /superagent or /delegate invokes it. Never delegate ordinary requests proactively."
license: MIT
---

# Herdr delegate

Orchestrate parallel claude/pi/omp workers through Herdr. You (the orchestrator) slice the work, write briefs, start and prompt workers, wait, verify, and integrate. Workers share the current git tree; safety comes from disjoint file ownership, not isolation.

Two backends run the same procedure. The `herdr` backend (Herdr TUI) is described in sections 2-11. The `hc` backend (Herdr desktop app) is section 12, which replaces the steps listed in the table in section 2.

## 1. When

Only on an explicit delegation request from the user, `/superagent`, or `/delegate`. Delegation never decides anything that requires user approval: approvals, trust dialogs, scope changes, and open questions go back to the user.

## 2. Preconditions

- Pick the backend, first match wins:
  1. `test "${HERDR_ENV:-}" = 1` passes: backend `herdr`. Follow sections 3-11 as written.
  2. `HC_TERMINAL_SOCKET` and `HC_TERMINAL_ID` are both set (Herdr desktop app): backend `hc`. Follow section 12 wherever the table below says so.
  3. Neither: tell the user to start this agent inside `herdr` or in the Herdr desktop app, and stop.
- `command -v jq` must succeed (all Herdr and hc responses are parsed with jq). For backend `hc`, `command -v hc` must succeed too.
- Record a baseline snapshot of the working tree to `$RUN_DIR/baseline.tree` (done in step 5) so worker changes can be attributed.
- Load the `herdr` skill for CLI semantics (IDs, states, read sources, safety rules).

Backend `hc` replaces these steps with section 12; every other step (4 Slice, 6 Briefs, 10 Verify) is shared:

| Step | `herdr` | `hc` |
|---|---|---|
| 3 Worker kind | `herdr agent get "$HERDR_PANE_ID"` | 12.1 |
| 5 Run setup | workspace + one tab per worker | 12.2 (no workspace) |
| 7 Start | `herdr agent start` | 12.3 |
| 8 Dispatch and wait | `herdr agent prompt --wait` | 12.4 |
| 9 Collect and resume | `herdr agent get/read/wait` | 12.5 |
| 11 Cleanup | `herdr workspace close` | 12.6 |

## 3. Worker kind

```bash
KIND=$(herdr agent get "$HERDR_PANE_ID" | jq -r '.result.agent.agent // empty')
case "$KIND" in pi|omp|claude) ;; *) KIND=pi ;; esac
```

For `KIND=omp`, pass no model flags: workers inherit the user's settings and active profile. omp has no role mapping.

For `KIND=pi`, every slice has a **role** (`task` default, `slow` hard/risky, `smol` trivial; same table as claude below). Resolve each slice's role with `pi-worker-model <role>`:

- It prints `<provider> <id> <effort>`: append `-- --provider <provider> --model <id>` to `agent start`, plus `--thinking <effort>` unless effort is `-` (then omit `--thinking`).
- It prints nothing (role config missing or disabled): pass no flags; the worker inherits the user's settings.
- A model the user names wins over the role: append `-- --model <provider/id>` instead.

For `KIND=claude`, every slice has a **role**: the name of an agent in `~/.claude/agents` (the active role set, switched with `claude-roles`). Start the worker with `-- --agent <role>`; the role supplies the model, effort and system prompt. Default role is `task`. Before starting any worker, check every slice's role with `test -f ~/.claude/agents/<role>.md`; if any file is missing, start no workers: show the user the missing role and ask which role to use. If the user names a worker model, append `--model <model-id>` (e.g. `claude-opus-5-5[1m]`; keep the `[1m]` suffix or the worker loses the 1M context window) after `--agent <role>`; the explicit model wins over the role's model.

## 4. Slice

- Read enough code to list the files each unit of work will create or modify.
- Merge units that share any file into one slice.
- Worker count: if the user names a number N, treat it as a ceiling and spawn `min(N, independent slices)`; if fewer slices exist than N, say so in the table (e.g. "asked for 10, plan has 4 disjoint slices"). Never split a file across workers or invent busywork to reach N. With no number named, the ceiling is 6. Absolute cap is 12: if the user asks for more, start no workers and ask them to confirm a lower number.
- Each slice gets: goal, owned files (the only files it may create/edit), read-only context files, acceptance criteria, validation commands.
- Work that cannot be parallelized stays with you.

Print this table before spawning:

| Worker | Owned files | Goal | Validation |
|---|---|---|---|

For `claude` and `pi` workers, add a Role column (omp has no roles):

| Worker | Role | Owned files | Goal | Validation |
|---|---|---|---|---|

For `pi`, also add a Model column with the resolved model (`<provider>/<id> <effort>`, or `inherit`), after Role.

Pick each role:

| Slice | Role |
|---|---|
| Normal implementation, clear scope | `task` |
| Hard, ambiguous, or risky (security, migrations, tricky logic) | `slow` |
| Trivial: rename, formatting, docs-only | `smol` |

Roles are shown in the table. The user approves them at the plan gate that `/delegate` (or an unapproved plan in `/superagent`) stops at.

With an already-approved plan `/superagent` does not stop, so the user sees the roles in the printed table and can override them only by naming them in the command ("worker 2 as slow").

## 5. Run setup

One shell call:

```bash
SA_ROOT="${TMPDIR:-/tmp}/superagent"; mkdir -p "$SA_ROOT"
# Fresh dir per run (4 hex chars), never reuse old results; RUN_DIR stays empty unless our own mkdir succeeded.
RUN_DIR=
for _ in $(seq 50); do RUN_ID=$(openssl rand -hex 2); mkdir "$SA_ROOT/$RUN_ID" 2>/dev/null && { RUN_DIR="$SA_ROOT/$RUN_ID"; break; }; done
if [ -n "$RUN_DIR" ]; then
  # Working-tree snapshot (tracked + untracked, minus ignored) via a private index;
  # the real index is never touched. Not a git repo → no baseline.tree, skip step 10's ownership check.
  if git rev-parse --git-dir >/dev/null 2>&1; then
    cp "$(git rev-parse --git-path index)" "$RUN_DIR/index" 2>/dev/null || true
    GIT_INDEX_FILE="$RUN_DIR/index" git add -A && GIT_INDEX_FILE="$RUN_DIR/index" git write-tree > "$RUN_DIR/baseline.tree"
  fi
  WS_JSON=$(herdr workspace create --cwd "$PWD" --label "sa-$RUN_ID" --env SUPERAGENT_RUN="$RUN_ID" --env SUPERAGENT_WORKER=1 --no-focus)
  WS_ID=$(jq -r '.result.workspace.workspace_id' <<<"$WS_JSON")
  ROOT_TAB=$(jq -r '.result.tab.tab_id' <<<"$WS_JSON"); ROOT_PANE=$(jq -r '.result.root_pane.pane_id' <<<"$WS_JSON")
  printf 'RUN_ID=%s RUN_DIR=%s WS_ID=%s ROOT_TAB=%s ROOT_PANE=%s\n' "$RUN_ID" "$RUN_DIR" "$WS_ID" "$ROOT_TAB" "$ROOT_PANE"
else
  echo "ABORT: cannot create a run dir under $SA_ROOT" >&2
fi
```

Shell variables do not persist between tool calls everywhere: carry the printed values forward literally. (Backend `hc` uses the same script without the `WS_*`/`ROOT_*` lines; see 12.2, and keep the two in step.)

- Worker names: `sa-$RUN_ID-<n>` for n = 1..N (fits `[a-z][a-z0-9_-]{0,31}`).
- Worker 1 uses `ROOT_PANE`: `herdr tab rename "$ROOT_TAB" "sa-$RUN_ID-1"`.
- Workers 2..N each get a tab:
  ```bash
  herdr tab create --workspace "$WS_ID" --cwd "$PWD" --label "sa-$RUN_ID-<n>" --env SUPERAGENT_RUN="$RUN_ID" --env SUPERAGENT_WORKER=1 --no-focus
  ```
  The pane is `.result.root_pane.pane_id`.
- Never guess IDs. If any extracted field is `null` or empty, abort and show the JSON error.

## 6. Briefs

Write `$RUN_DIR/<name>.brief.md` per worker with the file-writing tool. Never interpolate brief text into a shell command. Template:

```markdown
# Task <name>

## Goal
<goal>

## Owned files (edit only these)
- <path>

## Read-only context
- <path>

## Acceptance
- <criterion>

## Validation commands
- `<command>`

## Rules
Do not commit, push, stage, or install dependencies unless listed. Do not edit files outside Owned files. Do not delegate or start other agents. Do not load the herdr or herdr-delegate skills. Do not ask the user questions: if a decision or missing info blocks you, stop and report status blocked with the question. These rules override any role instruction to ask the user questions.

## Report
Write `<RUN_DIR>/<name>.result.md` with frontmatter `status: done|blocked|failed`, then sections Changed files, Validation (commands + trimmed output), Notes/Questions. Your final chat line must be `SUPERAGENT_RESULT <name> <status>`.
```

Substitute the literal `RUN_DIR` path and worker name in the Report section.

## 7. Start

For each worker, start all before prompting any:

```bash
herdr agent start <name> --kind "$KIND" --pane <pane> --timeout 60000
```

For `claude` workers:

```bash
herdr agent start <name> --kind claude --pane <pane> --timeout 60000 -- --agent <role> [--model <model-id>]
```

For `pi` workers, add the resolved model flags (omit them when `pi-worker-model` printed nothing):

```bash
herdr agent start <name> --kind pi --pane <pane> --timeout 60000 [-- --provider <provider> --model <id> [--thinking <effort>]]
```

On `agent_not_ready` or a blocked start: `herdr agent read <name> --source recent-unwrapped --lines 60`, show the output to the user, and ask. Never answer approval or trust dialogs yourself.

Herdr does not detect every startup dialog: pi's project-trust prompt ("Trust project folder?") reports `idle`, and a prompt sent to it would type into the menu and press Enter on its default choice, Trust. So after all starts succeed, check every worker's screen before dispatching:

```bash
herdr agent read <name> --source visible --lines 40
```

If any screen shows a dialog or selection menu instead of the empty input editor, do not prompt that worker. Show the screen to the user and ask them to resolve it in the worker's tab (`herdr agent focus <name>`), then re-check.

## 8. Dispatch and wait

One shell call; set the shell tool timeout to 3600 s where the tool supports one:

```bash
for name in <names>; do
  { herdr agent prompt "$name" "Read and execute the task brief at $RUN_DIR/$name.brief.md exactly." \
      --wait --timeout 3500000 >"$RUN_DIR/$name.wait.json" 2>"$RUN_DIR/$name.wait.err"
    echo $? >"$RUN_DIR/$name.wait.rc"; } &
done; wait
```

Use a background `--wait` per worker. Do not `prompt` and then run a standalone `agent wait`: it returns immediately while the worker is still `idle` before starting its turn.

## 9. Collect

Per worker:

- Exit code: `$RUN_DIR/$name.wait.rc`. `0` → status is `jq -r '.result.agent.agent_status' "$RUN_DIR/$name.wait.json"`. Non-zero → error is `jq -r '.error.code' "$RUN_DIR/$name.wait.err"`.
- `blocked` → `herdr agent read <name> --source recent-unwrapped --lines 120`, relay the question to the user. Do not answer for them.
- `timeout` / `agent_prompt_stalled` → `herdr agent get <name>` and `herdr agent read <name>` before anything else. Never resend the prompt blindly.
- Read `$RUN_DIR/$name.result.md`. Missing file = not done. `status: blocked` → relay its Notes/Questions to the user.

Resuming a blocked worker:

- **Question in the result file or chat:** write the user's answer verbatim to `$RUN_DIR/$name.answer.md` with the file-writing tool (never put it in a shell string), then send it with the same per-worker form as step 8 and collect that worker again:
  ```bash
  { herdr agent prompt "$name" "Read the user's answer at $RUN_DIR/$name.answer.md, continue the brief at $RUN_DIR/$name.brief.md, and rewrite $RUN_DIR/$name.result.md." \
      --wait --timeout 3500000 >"$RUN_DIR/$name.wait.json" 2>"$RUN_DIR/$name.wait.err"
    echo $? >"$RUN_DIR/$name.wait.rc"; }
  ```
- **Approval/trust dialog in the worker's UI:** the user answers it in the worker's tab. Do not send a new prompt; wait with the same capture so collection reads fresh files:
  ```bash
  { herdr agent wait "$name" --timeout 3500000 >"$RUN_DIR/$name.wait.json" 2>"$RUN_DIR/$name.wait.err"
    echo $? >"$RUN_DIR/$name.wait.rc"; }
  ```

## 10. Verify

- Ownership (skip if there is no `baseline.tree`; say so in the summary). List the paths changed since the baseline, including re-edits of files that were already dirty:
  ```bash
  cp "$(git rev-parse --git-path index)" "$RUN_DIR/index" 2>/dev/null || true
  GIT_INDEX_FILE="$RUN_DIR/index" git add -A
  git diff --name-only "$(cat "$RUN_DIR/baseline.tree")" "$(GIT_INDEX_FILE="$RUN_DIR/index" git write-tree)"
  ```
  Every listed path must be in some worker's owned files; report violations as blocking.
- Re-run each worker's validation commands yourself.
- Summarize:

| Worker | Tab | Status | Changed files | Validation |
|---|---|---|---|---|

- Hand off to `/review` (PI.md step 3). Never commit.

## 11. Cleanup

- Every worker `done` and every result read → `herdr workspace close "$WS_ID"`.
- Any worker blocked/working/failed, or the user asked to keep it → leave the workspace; print `WS_ID` and the agent names.
- Keep `$RUN_DIR`: briefs and results are the audit trail.
- Never close panes, tabs, or workspaces this run did not create.

## 12. Backend `hc` (Herdr desktop app)

Use only when section 2 selected backend `hc`. The desktop app has no workspace/tab/pane CLI; its terminals are controlled with `hc` (`hc <cmd> --help` is the authority). Each worker is one terminal named `sa-$RUN_ID-<n>` and labelled `sa=$RUN_ID`. Slice (4), Briefs (6) and Verify (10) are unchanged; in the step-10 summary table the Tab column is the terminal name. Never use `hc send --force`: it types into a blocked worker's dialog.

### 12.1 Worker kind

```bash
case "$(hc get "$HC_TERMINAL_ID" --json | jq -r '.status.app // empty')" in
  claude-code) KIND=claude ;; omp) KIND=omp ;; *) KIND=pi ;; esac
```

Roles, `--agent <role>`, `pi-worker-model` and `--model` handling are exactly as in section 3. The agent argv is: `claude --agent <role> [--model <model-id>]`, `pi [--provider <provider> --model <id> [--thinking <effort>]]`, or `omp`.

### 12.2 Run setup

Same as section 5 without any workspace. One shell call:

```bash
SA_ROOT="${TMPDIR:-/tmp}/superagent"; mkdir -p "$SA_ROOT"
RUN_DIR=
for _ in $(seq 50); do RUN_ID=$(openssl rand -hex 2); mkdir "$SA_ROOT/$RUN_ID" 2>/dev/null && { RUN_DIR="$SA_ROOT/$RUN_ID"; break; }; done
if [ -n "$RUN_DIR" ]; then
  if git rev-parse --git-dir >/dev/null 2>&1; then
    cp "$(git rev-parse --git-path index)" "$RUN_DIR/index" 2>/dev/null || true
    GIT_INDEX_FILE="$RUN_DIR/index" git add -A && GIT_INDEX_FILE="$RUN_DIR/index" git write-tree > "$RUN_DIR/baseline.tree"
  fi
  printf 'RUN_ID=%s RUN_DIR=%s\n' "$RUN_ID" "$RUN_DIR"
else
  echo "ABORT: cannot create a run dir under $SA_ROOT" >&2
fi
```

Carry the printed values forward literally. Worker names are `sa-$RUN_ID-<n>`.

### 12.3 Start

`hc run` has no `--env`, so the worker variables go through `env`. Everything after `--` is the worker's argv. Start all workers before prompting any:

```bash
hc run --bg --name sa-$RUN_ID-<n> --label sa=$RUN_ID --cwd "$PWD" --no-notify --outlive-parent \
  -- env SUPERAGENT_RUN="$RUN_ID" SUPERAGENT_WORKER=1 <agent argv from 12.1>
```

`--no-notify` stops `hc` typing completion notes into your input (you wait explicitly in 12.4). `--outlive-parent` keeps workers alive if your own program ends. Then, per worker:

```bash
hc wait <name> --timeout 60 --json
hc get <name> --json | jq -r '.status.state'
hc read <name> --lines 40
```

The state must be `idle` and the screen must show the empty input editor. If the wait times out, the state is `blocked`/`unknown`, or the screen shows a dialog or selection menu (including a "Trust project folder?" prompt, which is not reported as blocked), do not prompt that worker. Show the screen to the user and ask them to resolve it (`hc attach <name>`; ctrl+\ detaches), then re-check. Never answer approval or trust dialogs yourself.

### 12.4 Dispatch and wait

Same shape as section 8, one shell call with the tool timeout at 3600 s where supported:

```bash
for name in <names>; do
  { hc send "$name" "Read and execute the task brief at $RUN_DIR/$name.brief.md exactly." \
      --wait --timeout 3500 --json >"$RUN_DIR/$name.wait.json" 2>"$RUN_DIR/$name.wait.err"
    echo $? >"$RUN_DIR/$name.wait.rc"; } &
done; wait
```

`hc send --wait` waits for the turn that this send started, so do not follow it with a standalone `hc wait`.

### 12.5 Collect and resume

Per worker, read `$RUN_DIR/$name.wait.json`:

- `.wait.ended == true` and `.wait.status` is `idle` or `done`: the turn finished. Read `$RUN_DIR/$name.result.md`; a missing file means not done, and `status: blocked` means relay its Notes/Questions to the user.
- `.wait.status == "blocked"`: `hc read <name> --lines 120`, relay the question to the user, do not answer for them.
- Anything else is not a finished turn: `.wait.ended == false`, `.wait.reason` of `timeout`, `exit` or `error`, a null or unknown `.wait.status`, or a non-zero `$RUN_DIR/$name.wait.rc`. Run `hc get <name> --json` and `hc read <name> --lines 120` before anything else, report to the user what the worker did (still running, exited, or errored), and never resend the prompt blindly.

Resuming a blocked worker:

- **Question in the result file or chat:** write the answer verbatim to `$RUN_DIR/$name.answer.md` with the file-writing tool, then send it with the 12.4 form and collect again:
  ```bash
  { hc send "$name" "Read the user's answer at $RUN_DIR/$name.answer.md, continue the brief at $RUN_DIR/$name.brief.md, and rewrite $RUN_DIR/$name.result.md." \
      --wait --timeout 3500 --json >"$RUN_DIR/$name.wait.json" 2>"$RUN_DIR/$name.wait.err"
    echo $? >"$RUN_DIR/$name.wait.rc"; }
  ```
- **Approval/trust dialog in the worker's UI:** the user answers it (`hc attach <name>`). Do not send a new prompt; wait with the same capture:
  ```bash
  { hc wait "$name" --timeout 3500 --json >"$RUN_DIR/$name.wait.json" 2>"$RUN_DIR/$name.wait.err"
    echo $? >"$RUN_DIR/$name.wait.rc"; }
  ```

### 12.6 Cleanup

Only terminals this run created, found by label:

```bash
hc ls --label sa=$RUN_ID --json | jq -r '.terminals[].name'
```

- Every worker `done` and every result read: for each name, `hc kill <name>` then `hc rm <name>` (the kill leaves a finished entry that `hc rm` removes).
- Any worker blocked/working/failed, or the user asked to keep it: leave the terminals; print the names and `hc attach <name>`.
- Keep `$RUN_DIR`: briefs and results are the audit trail.
- Never kill or remove a terminal without the `sa=$RUN_ID` label of this run.
