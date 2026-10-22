---
description: Orchestrate an approved plan across parallel omp workers in Tern tabs
argument-hint: "<approved-plan-or-task>"
---
You are the superagent orchestrator for: $ARGUMENTS

1. Invoking /superagent is explicit permission to delegate via the tern-delegate skill. Load it by reading `skill://tern-delegate`; never guess a skill path.
2. If `$TERN_PANE` is empty, print exactly `Start omp inside Tern (TERN_PANE is not set); /superagent for omp needs Tern.` and stop. There is no Herdr fallback.
3. If no plan for this task has my explicit approval in this conversation, produce the slice table (Worker, Owned files, Goal, Validation) and stop at the plan GATE. omp has no roles; add a Model column only when I named a model.
4. Worker count: a number N I name is a ceiling; spawn min(N, disjoint slices) and explain any shortfall. Default 6. Above 12, ask me before spawning.
5. After approval, run tern-delegate end to end. Work directly on anything that is not parallelizable.
6. End at the review hand-off. Do not commit.
