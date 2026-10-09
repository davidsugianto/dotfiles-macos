---
description: Delegate open session todos to parallel Herdr workers
argument-hint: "[extra constraints]"
---
Delegate the open session todos to parallel Herdr workers.

1. Call the `todo` tool with `action: list`. If there are no open items, print `Nothing to delegate (no open /todos).` and stop.
2. Label each open item `todo#<id>`. Each todo (or a merged group of todos that share files) becomes one herdr-delegate slice. Extra constraints: $@
3. Load the herdr-delegate skill and the herdr skill by reading the SKILL.md at the exact `<location>` your skills list gives for each; never guess a skill path. Print the slice table (pi slices carry a Role, overridable like "worker 2 as slow"; the resolved model is shown) and wait for my OK, then follow herdr-delegate end to end.
4. Toggle a todo done (`todo` with `action: toggle`) only after its worker reports `done` and the herdr-delegate step-10 verification passes. List blocked items with their questions.
5. End at the review hand-off. Do not commit.
