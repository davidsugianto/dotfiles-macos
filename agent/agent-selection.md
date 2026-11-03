# Agent selection

Model tier policy for skill handlers. A handler's `AGENT_SELECTION_FILE` row points
here. When a core tells a handler to spawn a subagent, the handler picks the tier that
fits the subagent's job and passes that tier's model and effort. A role-specific row in
the handler (`SUBAGENT_TYPE`, or a `*_SUBAGENT_MODEL`) overrides the tier for that role.

| Tier | Use for | Effort |
|---|---|---|
| planner | Designing, deciding, reviewing, anything where a wrong call is costly | high |
| executor | Ordinary scoped work: drafting, editing, running steps | high |
| scanner | Read-only sweeps: listing, grepping, summarising many files | medium |

## Claude Code

Fixed aliases, spelled the way the subagent tool accepts them.

| Tier | Model |
|---|---|
| planner | `opus` |
| executor | `sonnet` |
| scanner | `haiku` |

In a work session Claude Code's overlay remaps these to Sol / Terra (see
`docs/model-profiles.md`), so nothing else is needed.

## pi and omp

No fixed model IDs. Each tier follows a model role of the **active role set**, so the
same policy works under an edith (Anthropic) set and a work-cekatai (cekat gateway) set.

| Tier | Role |
|---|---|
| planner | `plan` |
| executor | `task` |
| scanner | `smol` |

To resolve a tier, read that role from the active role set and pass its model, and its
effort when it has a concrete one (`low`, `medium`, `high`), to the subagent. A bare model
or the `:auto` suffix is not a concrete effort: use the tier's effort from the table
above. Never hardcode a model ID for these tools.

| Tool | Where the active roles live |
|---|---|
| pi | `~/.pi/agent/extensions/pi-model-roles/config.yaml`, `roles.<role>` (the role set `pi-roles` copied into place; `/profile` only sets the session model and is separate) |
| omp | the profile the running session is on (`/profile` shows it); its roles are in `~/.omp/model-profiles/<name>.yml` `modelRoles.<role>`, and a role the profile omits comes from `modelRoles.<role>` in `~/.omp/agent/config.yml`. omp keeps no on-disk marker of the active profile |

If a pi role cannot be read (file missing, role absent), fall back to the handler's
`SUBAGENT_MODEL` and say so in the final answer, but only when the session itself runs
an Anthropic model. On a cekat (work) model, stop and ask the user, as on omp below.
A handler's `SUBAGENT_MODEL` is therefore the fallback executor model for pi.

On omp, resolve the role only from the profile the session is on. If you cannot tell
which profile that is, stop and ask the user. Do not read the global `config.yml` roles
or use `SUBAGENT_MODEL` as a silent guess: under a work profile both are Anthropic
models, which the cekat gateway does not serve.
