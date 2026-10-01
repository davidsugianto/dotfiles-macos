---
description: Prepare a conventional commit after review and verification
argument-hint: "[commit-message-context]"
---
Prepare a commit for the current changes. Optional context: $@

Do not commit yet.

1. Read `PI.md`, git status, staged and unstaged diffs, the latest review outcome, and fresh verification evidence.
2. Confirm that review findings are resolved or explicitly accepted, all applicable tests/lint/build/smoke checks have fresh passing evidence (with non-applicable checks explained), and no unrelated files would be included. If any prerequisite is missing or failed, state the blocker and stop.
3. Draft one imperative conventional commit message matching the actual diff. Do not stage or modify files unless the user explicitly asks.
4. Show: proposed commit message, exact files that would be committed, diff summary, and verification evidence.

End with the PI.md commit gate: ask for explicit approval. Only after the user says yes may you stage and create the commit.
