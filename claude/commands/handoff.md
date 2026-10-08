---
description: List active handoffs and archive finished ones
argument-hint: ""
---
Manage handoff documents in `~/.claude/handoffs/`.

1. If the directory does not exist, print `No handoffs (~/.claude/handoffs is empty).` and stop.
2. For every `*.md` directly in `~/.claude/handoffs/` (not `_archived/`), read its frontmatter `title`, `status`, and `created`.
3. Move every document with `status: done` into `~/.claude/handoffs/_archived/` (create it if needed), using `mv` with no overwrite (`mv -n`). Do not touch other files.
4. Print a table of the remaining handoffs (filename, title, status, created), newest first, then list the files just archived.
5. Remind me that `/work-on-handoff <filename>` resumes one.
