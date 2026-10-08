---
description: Delegate open session todos to parallel Herdr workers
argument-hint: "[extra constraints]"
---
Delegate the open session todos to parallel Herdr workers.

1. Take the open (pending or in_progress) items from the current TodoWrite list. If there are none, print `Nothing to delegate (no open todos).` and stop.
2. Label each open item `todo#<n>` by its position in the list. Each todo (or a merged group of todos that share files) becomes one herdr-delegate slice. Extra constraints: $ARGUMENTS
3. Load the `herdr-delegate` and `herdr` skills with the Skill tool; never guess a skill path. Print the slice table and wait for my OK, then follow herdr-delegate end to end.
4. Mark a todo completed with TodoWrite only after its worker reports `done` and the herdr-delegate step-10 verification passes. List blocked items with their questions.
5. End at the review hand-off. Do not commit.
