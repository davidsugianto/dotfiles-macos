---
description: Create a handoff document for the current work
argument-hint: "[handoff-title]"
---
Create a handoff for the current work. Use the requested title if provided: $ARGUMENTS. If no title is provided, derive a short, specific title from the current work before creating the file.

1. Read the current conversation, git status, diff, and relevant files.
2. Write a concise document directly under `~/.claude/handoffs/` using the filename format `YYYY-MM-DD-handoff-<kebab-title>.md`.
3. Use this frontmatter exactly:

```yaml
---
title: <title>
status: active
created: YYYY-MM-DD
---
```

4. Include: Context, Done, Remaining, Next step, Files, and Validation.
5. Record concrete commands, file paths, blockers, assumptions, and the next action. Do not claim unfinished work is done.

Do not write inside `_archived/`. Report the created path when finished.
