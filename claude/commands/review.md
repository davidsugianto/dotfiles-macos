---
description: Review the current diff before verification
argument-hint: "[scope-or-focus]"
---
Review the current changes. Optional focus: $ARGUMENTS

Review only: do not edit files, install dependencies, commit, or dismiss findings without evidence.

1. Read `~/.claude/CLAUDE.md`, `git diff`, `git diff --cached`, git status, relevant surrounding code, and applicable tests.
2. Review correctness, regressions, error handling, maintainability, test coverage, and adherence to the approved plan.
3. When the change handles sensitive inputs, authorization, secrets, external requests, or CI/CD, also perform a security-focused review.
4. Report only actionable findings. For each finding, include severity, file and line, concrete impact, and a concise remediation. Clearly separate blocking findings from suggestions.
5. If no findings remain, state what was reviewed and its remaining verification needs; do not claim the changes are complete or tested. If blocking findings remain, report them and ask how to proceed.

End with a gate: wait for the user to authorize `/fix` or `/test`.
