---
name: tern-delegate
description: "Delegate work to omp worker agents in a dedicated Tern session (one tab per worker), with disjoint file ownership, file-based briefs and results, and verified integration. Use only when the user explicitly asks to delegate/spawn/parallelize, or when /superagent invokes it. Never delegate ordinary requests proactively."
license: MIT
---

<!-- Tern port of herdr-delegate (pi/skills/herdr-delegate); verified against tern 0.9.5. -->

# Tern delegate

Orchestrate parallel omp workers through Tern. You (the orchestrator) slice the work, write briefs, start and prompt workers, wait, verify, and integrate. Workers share the current git tree; safety comes from disjoint file ownership, not isolation.

## 1. When

Only on an explicit delegation request from the user or `/superagent`. Delegation never decides anything that requires user approval: approvals, trust dialogs, scope changes, and open questions go back to the user.

## 2. Preconditions

- `test -n "${TERN_PANE:-}"` must pass. Otherwise print exactly `Start omp inside Tern (TERN_PANE is not set); /superagent for omp needs Tern.` and stop. There is no Herdr fallback.
- `command -v tern jq` must succeed (Tern JSON output is parsed with jq).
- Record a baseline snapshot of the working tree to `$RUN_DIR/baseline.tree` (done in step 5) so worker changes can be attributed.

Every `tern` command defaults to the caller's window (`$TERN_WINDOW_KEY`). omp draws into a Tern surface, so plain capture returns empty text: always capture omp blocks with `--surfaces`. Even then a capture holds only omp's message transcript, never its input editor, menus, or dialogs (verified with tern 0.9.5).

## 3. Worker kind

Workers are always omp. omp has no roles: pass no model flags, so workers inherit the user's settings and active `/profile`. A model the user names wins: launch that worker with `omp --model <provider/id>`.

## 4. Slice

- Read enough code to list the files each unit of work will create or modify.
- Merge units that share any file into one slice.
- Worker count: if the user names a number N, treat it as a ceiling and spawn `min(N, independent slices)`; if fewer slices exist than N, say so in the table (e.g. "asked for 10, plan has 4 disjoint slices"). Never split a file across workers or invent busywork to reach N. With no number named, the ceiling is 6. Absolute cap is 12: if the user asks for more, start no workers and ask them to confirm a lower number.
- Each slice gets: goal, owned files (the only files it may create/edit), read-only context files, acceptance criteria, validation commands.
- Work that cannot be parallelized stays with you.

Print this table before spawning:

| Worker | Owned files | Goal | Validation |
|---|---|---|---|

Add a Model column (`<provider>/<id>` or `inherit`) after Worker only when the user named a model.

## 5. Run setup

One shell call. Fill in `N` and, if the user named a model, `OMP`:

```bash
N=<worker count>
OMP=(omp)   # or: OMP=(omp --model <provider/id>)
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
  printf 'RUN_ID=%s RUN_DIR=%s\n' "$RUN_ID" "$RUN_DIR"
  SESSION=
  for n in $(seq 1 "$N"); do
    name="sa-$RUN_ID-$n"
    if [ "$n" = 1 ]; then
      J=$(tern new session "sa-$RUN_ID" --cwd "$PWD" --keep-open --json -- env SUPERAGENT_RUN="$RUN_ID" SUPERAGENT_WORKER=1 "${OMP[@]}")
      SESSION=$(jq -r '.session // empty' <<<"$J")
    else
      J=$(tern new tab "$SESSION" --cwd "$PWD" --keep-open --json -- env SUPERAGENT_RUN="$RUN_ID" SUPERAGENT_WORKER=1 "${OMP[@]}")
    fi
    BLOCK=$(jq -r '.block // empty' <<<"$J")
    if [ -z "$SESSION" ] || [ -z "$BLOCK" ]; then
      echo "ABORT at $name: $J (killing this run's session ${SESSION:-none})" >&2
      [ -n "$SESSION" ] && tern kill session "$SESSION"
      break
    fi
    echo "$BLOCK" > "$RUN_DIR/$name.block"
    tern rename "$BLOCK" "$name"
    printf 'SESSION=%s %s BLOCK=%s\n' "$SESSION" "$name" "$BLOCK"
  done
else
  echo "ABORT: cannot create a run dir under $SA_ROOT" >&2
fi
```

Shell variables do not persist between tool calls: carry the printed values (`RUN_ID`, `RUN_DIR`, `SESSION`, each worker's block id) forward literally.

- Worker names: `sa-$RUN_ID-<n>` for n = 1..N; each tab is renamed to its worker's name. New sessions do not steal focus.
- Worker 1 is the session's first block; workers 2..N are new tabs in that session.
- Different models per worker: run the `tern new` call for that worker with its own `omp --model <provider/id>`.
- Blocks are launched with `--keep-open` so an exited worker's screen stays readable; step 11 closes them.
- Never guess IDs. On `ABORT`, start no workers, kill this run's own session (if one was created), and show the JSON.

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
Do not commit, push, stage, or install dependencies unless listed. Do not edit files outside Owned files. Do not delegate, start other agents, or create Tern blocks, tabs, or sessions. Do not load the tern-delegate, herdr, or herdr-delegate skills. Do not ask the user questions: if a decision or missing info blocks you, stop and report status blocked with the question. These rules override any role instruction to ask the user questions.

## Report
Write `<RUN_DIR>/<name>.result.md` with frontmatter `status: done|blocked|failed`, then sections Changed files, Validation (commands + trimmed output), Notes/Questions. Your final chat line must be `SUPERAGENT_RESULT <name> <status>`.
```

Substitute the literal `RUN_DIR` path and worker name in the Report section.

## 7. Start

The workers were launched in step 5. Before prompting any, check every worker:

```bash
tern wait <block> --until idle=3000 --timeout 60   # 0 = output settled, 124 = out of time
tern process <block> --json | jq -r '.child.name'   # must print omp
tern process <block> --json | jq -r '.child.pid' > "$RUN_DIR/<name>.pid"   # only after the name check passes
tern capture <block> --surfaces
```

Use `tern process`, not `tern ls`, for liveness (`ls` shows the wrapper shell). The launch uses `env ... omp` and env execs omp, so `.child.pid` is omp's PID for the block's whole life (the process in control of the terminal can change while omp runs commands). If `.child.name` is not omp, show the capture to the user and stop for that worker.

The capture cannot show a startup dialog or selection menu, so the `.child.name` check is the only automated gate. A pasted prompt sent into a dialog would type into the menu and Enter would pick its default. If the user reports a dialog in any worker tab, or one is expected (first omp run on this machine, a login or profile change), do not prompt that worker: ask the user to resolve it in the tab (`tern focus <block>`) and confirm before you dispatch. Never answer approval or trust dialogs yourself.

## 8. Dispatch and wait

Dispatch each worker (`<block>` from `$RUN_DIR/<name>.block`):

```bash
tern send <block> paste "Read and execute the task brief at $RUN_DIR/<name>.brief.md exactly."
tern send <block> keys Enter
```

Then wait in one shell call; set the shell tool timeout to 3600 s. Each worker gets a background poll that ends when its result file exists, its omp process (PID from `$RUN_DIR/<name>.pid`) is gone, or 3500 s pass:

```bash
RUN_DIR=<RUN_DIR>
for name in <names>; do
  { pid=$(cat "$RUN_DIR/$name.pid"); end=$((SECONDS + 3500)); st=timeout
    while [ "$SECONDS" -lt "$end" ]; do
      [ -f "$RUN_DIR/$name.result.md" ] && { st=result; break; }
      kill -0 "$pid" 2>/dev/null || { st=exited; break; }
      sleep 15
    done
    [ "$st" != result ] && [ -f "$RUN_DIR/$name.result.md" ] && st=result
    echo "$st" >"$RUN_DIR/$name.wait.status"; } &
done; wait; for name in <names>; do echo "$name $(cat "$RUN_DIR/$name.wait.status")"; done
```

Tern limitation: it has no agent state (no Herdr-style idle/working/blocked). A worker stuck on an approval prompt just looks busy until the poll times out. When a worker runs long, read its transcript (`tern capture <block> --surfaces`) and ask the user to look at its tab (`tern focus <block>`): an approval prompt shows only in the tab, never in a capture.

## 9. Collect

Per worker, by `$RUN_DIR/<name>.wait.status`:

- `result` → read `$RUN_DIR/<name>.result.md`; its frontmatter `status` is the worker's status. `status: blocked` → relay its Notes/Questions to the user. Do not answer for them.
- `timeout` → `tern capture <block> --surfaces --scrollback` and show the user the tail before anything else, then ask them to check the tab (`tern focus <block>`) for an approval prompt the capture cannot show. Never resend the prompt blindly.
- `exited` → omp is gone; report the worker as failed (with `tern capture <block> --surfaces --scrollback` tail if useful).

Resuming a blocked worker:

- **Question in the result file or chat:** write the user's answer verbatim to `$RUN_DIR/<name>.answer.md` with the file-writing tool (never put it in a shell string). Then remove the stale result and paste the resume prompt:
  ```bash
  rm -f "$RUN_DIR/<name>.result.md"
  tern send <block> paste "Read the user's answer at $RUN_DIR/<name>.answer.md, continue the brief at $RUN_DIR/<name>.brief.md, and rewrite $RUN_DIR/<name>.result.md."
  tern send <block> keys Enter
  ```
  Then run step 8's wait loop for that worker alone and collect it again.
- **Approval/trust dialog in the worker's UI:** the user answers it in the worker's tab (`tern focus <block>`). Do not paste a new prompt; run step 8's wait loop for that worker again.

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

- Hand off to review. Never commit.

## 11. Cleanup

- Every worker `done` and every result read → `tern close <block>` for each worker block, then `tern kill session <session-id>`.
- Step 5 `ABORT` → the session was already killed there; nothing else to close. Show the ABORT JSON.
- Any worker blocked/failed/timed out, or the user asked to keep it → leave the session; print its name (`sa-<RUN_ID>`), session id, and the worker block ids.
- Keep `$RUN_DIR`: briefs and results are the audit trail.
- Never close blocks, tabs, or sessions this run did not create.
