---
description: Verify the current changes with real checks
argument-hint: "[scope-or-extra-checks]"
---
Verify the current changes. Optional scope: $@

Verification only: do not edit files, install dependencies, commit, or claim success without fresh command output.

1. Read `~/.pi/agent/PI.md`, the current diff, project documentation, and the relevant package or build configuration to identify the real validation commands.
2. Run relevant tests, lint/format checks, build/type checks, and a smoke check of the changed path where applicable. For documentation or configuration changes, use appropriate validation instead. Prefer the full project checks; if a full check is impractical or does not apply, state why and run the broadest feasible equivalent.
3. Read every command's exit status and output. Report commands, results, failures, skipped checks, and any environment limitation exactly.
4. On a failure, stop and use systematic debugging before proposing a fix. Do not conceal pre-existing failures.

End at the PI.md test gate: show the diff summary and fresh test output, then wait for the user before `/commit`.
