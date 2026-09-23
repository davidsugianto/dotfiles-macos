# subagents-pi

> Vendored from [luongnv89/pi-extensions](https://github.com/luongnv89/pi-extensions/tree/main/extensions/subagents-pi)
> (MIT) into this repo because it isn't published to npm — see
> `dotfiles-macos/README.md`'s "pi status & subagent extensions" section for
> why and how it's installed (`pi install <absolute path to this directory>`,
> not `pi install npm:subagents-pi`). Re-sync by hand from the upstream URL
> above if it updates; nothing here pulls changes automatically.

Pi extension that shows a **fleet metrics panel** for every managed subagent: **context usage**, **output TPS**, and **thinking level with model name**.

Designed as a companion to [`@tintinweb/pi-subagents`](https://www.npmjs.com/package/@tintinweb/pi-subagents), which handles spawning, FleetView, and the `Agent` tool. This extension listens to the `pi.events` lifecycle bus and reads the shared agent registry for live stats.

## Install

```bash
# Orchestration (required for subagents)
pi install npm:@tintinweb/pi-subagents

# Metrics panel (this extension) — not on npm, install from this repo
pi install ~/Artifacts/labs/src/dotfiles-macos/pi/extensions/subagents-pi
```

Reload Pi: `/reload`

## Usage

- The panel appears **below the editor** and lists only **active** subagents (`running` / `queued`). Completed, errored, aborted, and stopped agents leave the list immediately.
- Layout is an ops-console card: header summary (`N active · M queued`), glyph status, identity, then width-safe metric lines (context/TPS/duration/tools + thinking/model).
- `/subagents-pi` — toggle the panel
- `/subagents-pi-refresh` — refresh metrics and drop finished or removed records

## What each row shows

| Field | Source |
|-------|--------|
| Status | Glyph + compact label (`● run`, `○ queue`) |
| Context | Current context tokens (or `—` when unavailable) + context-window % (when available) + compaction count |
| TPS | Output tokens ÷ elapsed time (approximate session average); queued agents show `waiting` |
| Duration / tools | Elapsed time and tool-use count |
| Thinking/model | Runtime session thinking level with runtime provider/model; invocation settings are used as fallback |

## License

MIT
