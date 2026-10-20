# Model profiles: Claude Code, pi and omp

One page that shows which model each role uses in each tool, and how to switch
sets. The files in the repo are the source of truth; this is a summary.

All three tools split work into the same roles:

| Role | Used for |
|---|---|
| `default` | The main session (what you talk to) |
| `smol` | Small, low-risk edits and lookups |
| `commit` | Commit messages, PR descriptions, changelogs |
| `task` | Ordinary scoped implementation work |
| `plan` | Plans and designs, no edits |
| `slow` | Hard, ambiguous or high-risk problems |
| `web` | Web research and summarising (work sets: pi and omp; Claude Code has none) |

Two kinds of model sets exist:

- **Anthropic sets** (Claude Code and omp only; pi has none) use your Claude OAuth
  login (`/login`), never the cekat gateway.
- **Work sets** (`work-cekatai-*`) route through the internal cekat LiteLLM
  gateway (`$CEKAT_API_KEY`) to GPT-6 Luna (fast) and GPT-6.1 Sol (deep).

Names used below: Haiku = `claude-haiku-4-5` (Claude Code and the omp edith profiles use `claude-haiku-5-5`), Sonnet = `claude-sonnet-5-5`, Opus = `claude-opus-5-5`,
Luna = `azure_ai/gpt-6-luna`, Sol = `azure_ai/gpt-6.1-sol`. Effort is shown
after the model; `-` means none is set.

## Claude Code

Role subagents in `claude/model-roles/<set>/*.md`. All models carry the `[1m]`
(1M context) suffix, which is omitted from the tables.

| Role | `edith-default` (alias `default`) | `edith-superpower` (alias `personal`) | `work-cekatai-default` (alias `work-default`) | `work-cekatai-superpower` (alias `work-superpower`) |
|---|---|---|---|---|
| smol | Sonnet, high | Opus, medium | Luna | Luna, high |
| commit | Haiku 5.5, high | Haiku 5.5, high | Luna | Luna |
| task | Sonnet, high | Sonnet, high | Sol | Sol |
| plan | Opus, high | Opus, high | Sol, high | Sol, high |
| slow | Opus, high | Opus, high | Sol, high | Sol, high |
| web | Sonnet, high | Sonnet, high | none | none |

Session overlays (`claude/profiles/*.json`, applied at launch with
`claude --settings`) set the main model, not the subagents:

| Overlay | Main model |
|---|---|
| `edith-default` | Sonnet, high |
| `edith-superpower` | Opus, high |
| `plan`, `slow` | Opus, high |
| `task` | Sonnet, medium |
| `smol`, `commit`, `web` | Haiku 5.5, high |
| `work-cekatai-default` | Luna (Sonnet/Opus/Haiku tiers map to Luna/Sol/Luna) |
| `work-cekatai-superpower` | Sol (Sonnet/Opus/Haiku tiers map to Sol/Sol/Luna) |

Switching:

```bash
claude-roles                        # show the active role set
claude-roles edith-superpower       # or: edith-default | work-default | work-superpower
claude-profile plan                 # one session on an overlay
claude-work [work-default|work-superpower]   # session through the cekat gateway
```

`claude-roles` repoints `~/.claude/agents`, so it affects every open session;
restart them afterwards. `claude-work` needs `$CEKAT_API_KEY` and warns if the
active role set does not match the profile.

## pi

Role sets in `pi/model-roles/*.yaml` (the pi-model-roles extension). Pi's
startup default model is Luna (`settings.json`) and is independent of the role
set. Luna reports no thinking levels, so effort on Luna is effectively off.

| Role | `work-cekatai-default` (alias `work-default`) | `work-cekatai-superpower` (alias `work-superpower`) |
|---|---|---|
| default | Luna, high | Sol, off |
| smol | Luna, off | Luna, high |
| commit | Luna, off | Luna, off |
| task | Sol, off | Sol, off |
| plan | Sol, high | Sol, high |
| slow | Sol, high | Sol, high |
| web | Luna, high | Luna, high |

Account/identity profiles (`pi/profiles/*.json`, pi-profile `/profile <name>`)
set a session model: one per role (`smol`, `commit`, `task`, `plan`, `slow`,
`web`), plus `work-cekatai-default` (Luna) and `work-cekatai-superpower` (Sol).
`pi/profiles/.active` is runtime state and is git-ignored. pi has no Anthropic
sets; use omp or Claude Code for those.

Switching:

```bash
pi-roles work-default            # or: work-superpower
# then /reload in every open pi session
/profile work-cekatai-superpower   # inside pi
```

`pi-roles` copies the file into place (pi-model-roles cannot save through a
symlink), so it needs `/reload` and has no live in-session command. Herdr pi
workers take their model from the active set via `pi-worker-model <role>`.

## omp

Model profiles in `omp/model-profiles/*.yml`, layered over the global roles in
`omp/config.yml`. Effort is a suffix: `:high`, or `:auto` (omp picks). A bare
model has no suffix.

| Role | `config.yml` (global) | `edith-default` | `edith-superpower` | `work-cekatai-default` | `work-cekatai-superpower` |
|---|---|---|---|---|---|
| default | Sonnet, auto | Sonnet, auto | Opus, auto | Luna, auto | Sol, auto |
| smol | Haiku, auto | Sonnet, auto | Sonnet, auto | Luna, auto | Luna, auto |
| commit | Haiku, auto | Haiku 5.5, auto | Haiku 5.5, auto | Luna, auto | Luna, auto |
| task | Sonnet, auto | Sonnet, auto | Opus, auto | Sol, auto | Sol, auto |
| plan | Opus, high | Opus, auto | Opus, auto | Sol, auto | Sol, auto |
| slow | Opus, high | Opus, auto | Opus, auto | Sol, auto | Sol, auto |
| web | Haiku, auto | Sonnet, auto | Sonnet, auto | Luna, auto | Sol, auto |

omp has no alias layer: switch in-session with `/profile <name>` (the
omp-model-profiles plugin). A profile that omits a role falls back to the
global role.

## Cross-tool differences

- **Names are not fully aligned.** Claude Code and omp call their Anthropic sets
  `edith-default` / `edith-superpower` (omp follows Claude Code's model mix, with
  `:auto` effort); pi has no Anthropic sets. The work sets share one name
  everywhere.
- **Same intent, different mix.** `edith-superpower` puts Opus on plan and slow
  in both tools that have it. Claude Code runs
  every role at `high` (Opus on `smol`, Sonnet on `task`). omp's edith profiles
  use the same models except in `edith-superpower`, which swaps them (Sonnet on
  `smol`, Opus on `task`), and run every role at `:auto`.
- **Where each is applied.** Claude Code and pi apply role sets to subagents and
  Herdr workers; omp applies them to its own role routing.
- **Gateway quirk.** The cekat gateway rejects tool calls on
  `/v1/chat/completions` for Luna and Sol, so both are routed via
  `api: openai-responses` in `pi/models.json` and `omp/models.yml`. See the
  "Cekat model tool-call routing" section in `README.md`.

## Older model ids kept on purpose

Not everything is on the 5.5 generation. These are deliberate, not drift:

- pi's per-role identity profiles (`plan`, `slow`, `task`) name `claude-opus-5` /
  `claude-sonnet-5`, not the `-5-5` ids the role sets use.
- Many skill handlers under `pi/skills/` default their `SUBAGENT_MODEL` to
  `anthropic/claude-sonnet-5`.

Upgrade any of these by editing the file named above; nothing else depends on them.
