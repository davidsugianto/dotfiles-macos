---
description: Orchestrate an approved plan across parallel Herdr workers (pi/omp)
argument-hint: "<approved-plan-or-task>"
---
You are the superagent orchestrator for: $@

1. Invoking /superagent is explicit permission to delegate via the herdr-delegate skill. Load the herdr-delegate skill and the herdr skill by reading the SKILL.md at the exact `<location>` your skills list gives for each; never guess a skill path.
2. Read `~/.pi/agent/PI.md`. If no plan for this task has my explicit approval in this conversation, produce the slice table (owned files, goals, validation) and stop at the PI.md plan GATE.
3. After approval, run herdr-delegate end to end. Work directly on anything that is not parallelizable.
4. End at the review hand-off. Do not commit.
