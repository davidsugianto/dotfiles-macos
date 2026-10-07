---
description: Continue work from a handoff document
argument-hint: "<yyyy-mm-dd-handoff-title.md>"
---
Work on this handoff document: $@

1. Resolve it only from `~/.pi/agent/handoffs/<filename>`; do not use `_archived/`.
2. Read the handoff before changing anything. If the filename is missing or does not exist, stop and report the valid active filenames.
3. Mark its frontmatter `status: in_progress` before implementation.
4. Implement the Remaining and Next step sections, preserving useful context and updating Done, Files, and Validation with real results.
5. Run the smallest relevant tests or checks.
6. When all work is complete, set frontmatter `status: done`. Leave completed-file movement to `/handoff`, which archives done documents.

Do not mark the handoff done while work, tests, or blockers remain.
