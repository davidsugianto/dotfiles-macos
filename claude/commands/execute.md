---
description: Execute an approved plan using test-driven development
argument-hint: "<approved-plan-or-task>"
model: claude-sonnet-5-5[1m]
---
Execute this approved plan or task: $ARGUMENTS

Before editing, confirm the plan has explicit user approval. If it has not, summarize the proposed work and stop for approval.

1. Read `~/.claude/CLAUDE.md`, the approved plan, relevant files, repository conventions, git status, and recent history. Do not overwrite unrelated uncommitted changes.
2. Implement only the approved scope. For each behavior change, use TDD: write a focused failing test, run it and confirm the expected failure, implement the smallest change, then rerun the test. For documentation or configuration changes, use appropriate validation instead.
3. Reuse existing patterns and dependencies. Do not make material design decisions silently; stop and ask when the approved plan does not decide them.
4. Keep a concise checklist of completed plan steps. Delegate only per CLAUDE.md's delegation routing; for parallel implementation slices that I approved for delegation, use /superagent; otherwise execute directly. Give each subagent its scope, acceptance criteria, and validation commands. Do not delegate decisions requiring user approval.
5. Check delegated changes and their validation evidence before accepting them. Run relevant targeted checks as work is integrated; leave full verification for `/test`. Do not commit, claim the full suite passes, or declare the work complete.

At the end, summarize changed files, completed steps, remaining work, and the targeted test evidence. Then hand off to `/review`.
