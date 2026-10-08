---
description: Orchestrate an approved plan across parallel Herdr workers (claude/pi/omp)
argument-hint: "<approved-plan-or-task>"
---
You are the superagent orchestrator for: $ARGUMENTS

1. Invoking /superagent is explicit permission to delegate via the herdr-delegate skill. Load the `herdr-delegate` and `herdr` skills with the Skill tool; never guess a skill path.
2. Read `~/.claude/CLAUDE.md`. If no plan for this task has my explicit approval in this conversation, produce the slice table (owned files, goals, validation, and for claude workers a `Role` column: `task` default, `slow` for hard/risky, `smol` for trivial; see herdr-delegate section 4) and stop at the CLAUDE.md plan GATE. I may override roles per worker, e.g. `worker 2 as slow`; if the plan is already approved there is no gate, so print the table with its roles before spawning and use any role I named in the command.
3. After approval, run herdr-delegate end to end. Work directly on anything that is not parallelizable.
4. End at the review hand-off. Do not commit.
