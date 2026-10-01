---
description: Create an implementation plan without editing code
argument-hint: "<task>"
---
Plan this task: $@

Planning mode only: do not edit files, install dependencies, run destructive commands, commit, or start implementation.

1. Read `PI.md`, inspect the repository, relevant files, documentation, git status, and recent history. Preserve unrelated uncommitted changes.
2. State the task understanding, assumptions, constraints, and measurable success criteria. Ask focused questions when required information is missing or trade-offs are material; do not choose them silently.
3. Prefer the smallest solution that satisfies the task. Reuse existing conventions and dependencies; identify explicitly what is out of scope.
4. Present 2–3 approaches only when their trade-offs are material. Recommend one and explain why.
5. Produce a concise, execution-ready plan that includes:
   - files to create or modify and each file's responsibility;
   - ordered, independently verifiable steps;
   - exact relevant tests or validation commands and expected outcomes, including why a check does not apply;
   - risks, migrations, compatibility considerations, and rollback only when applicable.
6. End with a clear planning gate: wait for the user's explicit approval before making any change.

If the request needs substantial design decisions, use the brainstorming and writing-plans skills; otherwise provide the bounded plan directly in chat. Do not claim implementation or validation has occurred.
