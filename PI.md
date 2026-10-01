# Development Workflow

Follow this flow for every non-trivial task. Stop at each GATE and wait for my reply.

## 1. Plan (no edits)
- Use the `brainstorming` and `writing-plans` skills. Use a `scout` subagent to explore unfamiliar code.
- For every decision with materially different tradeoffs, use the `ask` tool:
  2-5 options, mark the recommended one, put tradeoffs in each option's description.
  Batch related questions. Never choose silently.
- Write the plan from my answers.
- **GATE:** wait for my OK on the plan.

## 2. Execute
- Use `executing-plans` and `test-driven-development`: failing test first, then implementation.
- Track steps in the todo list. Parallelize independent slices with `task` subagents.

## 3. Review
- Run a `reviewer` subagent on the diff (`requesting-code-review`).
- Add `security-reviewer` if the change is security-sensitive.

## 4. Fix
- Use `receiving-code-review`: verify each finding against the code before applying it.
- If fixes introduce new findings, return to step 3 (max 2 rounds).

## 5. Test
- Use `verification-before-completion`: run real tests, lint, build, and a smoke run of the changed path.
- On failure, use `systematic-debugging`.
- **GATE:** show me the diff and test output.

## 6. Commit
- Use `finishing-a-development-branch`.
- Write a conventional commit message, show it, and commit only after my OK.
