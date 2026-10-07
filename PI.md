# Development Workflow

Use this flow for non-trivial tasks; scale the depth to the change. For small documentation or configuration edits, use a short plan and relevant validation rather than inventing tests or a build. Preserve unrelated uncommitted changes. Stop at each GATE and wait for my reply.

## 1. Plan (no edits)
- Use `brainstorming` and `writing-plans` when the task warrants them. Explore unfamiliar code directly or with an available research subagent when useful.
- For decisions with materially different tradeoffs, ask me using the available tools or chat. Give 2-5 options, recommend one, and explain the tradeoffs. Never choose silently.
- Present a concise plan from my answers; use a written plan for larger work and an in-chat plan for bounded changes.
- **GATE:** wait for my OK on the plan.

## 2. Execute
- Follow the approved plan. For behavior changes, use `test-driven-development`: failing test first, then implementation. For docs/config changes, use appropriate validation instead.
- Track steps with the `todo` tool (/todos to view).
- Delegation routing: use the in-process `Agent` tool (pi-subagents) for read-only exploration and short self-contained lookups. Use Herdr workers (`/superagent`, `/delegate`, or the `herdr-delegate` skill) only when I ask for delegation/parallel work: each worker is a visible, persistent pi/omp session in a dedicated Herdr workspace and owns a disjoint set of files. Give every delegate its scope, acceptance criteria, and validation commands; never delegate decisions requiring my approval.
- Check delegated changes and their validation evidence before accepting them. Run relevant targeted checks as work is integrated; leave full verification for step 5.

## 3. Review
- Review the diff against the approved plan (`requesting-code-review`); use a reviewer subagent when available and useful.
- Include a security-focused review for security-sensitive changes.

## 4. Fix
- Use `receiving-code-review`: verify each finding against the code before applying it.
- If fixes introduce new findings, return to step 3 (max 2 rounds). If blocking findings remain, report them and ask how to proceed.

## 5. Test
- Use `verification-before-completion`: run relevant tests, lint, build, and a smoke check where applicable. Report what ran, its output, and why any check was skipped.
- On failure, use `systematic-debugging`; do not claim success or proceed to commit with unresolved failures.
- **GATE:** show me the diff summary and validation output.

## 6. Commit
- Use `finishing-a-development-branch`.
- Show the conventional commit message and exact files to be committed. Stage and commit only after my OK; exclude unrelated changes.

## Long-running work
- Before ending a session with unfinished work, run /do-handoff; resume later with /work-on-handoff <file> (handoffs live in ~/.pi/agent/handoffs, /handoff lists and archives them).
