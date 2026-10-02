---
description: Verify review findings and apply confirmed fixes
argument-hint: "<review-findings-or-instructions>"
---
Address these review findings or instructions: $@

1. Read `~/.pi/agent/PI.md`, the current diff, the cited code and tests, and the review findings.
2. Verify each finding against the code before changing anything. Explain and skip findings that are not reproducible, out of scope, or based on an incorrect premise.
3. For every confirmed behavioral fix, use TDD: add or update a focused failing test, verify its expected failure, make the smallest corrective change, and rerun the test.
4. Do not overwrite unrelated changes or expand scope. Ask the user before choosing a materially different remedy.
5. Summarize each finding as fixed, not applicable, or blocked, including the supporting test evidence.

Do not commit or claim full verification. If fixes were applied, hand off to `/review`; otherwise, ask whether to continue with `/test`.
