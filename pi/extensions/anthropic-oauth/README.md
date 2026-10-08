# pi-anthropic-auth

Pi extension that adds one command, `/anthropic-auth:status`, which reports:

- that the extension is loaded, with its version and module path;
- each Anthropic provider it checks (`anthropic` plus any extras from the config file) and that provider's credential type: OAuth, API key / other non-OAuth, configured but type unknown (provider has no models), no credentials, or not registered with Pi. Tokens are never printed, resolved, or refreshed;
- config warnings.

## What it does not do

It never alters requests. It registers no event hooks and no provider overrides. OAuth handling (headers, betas, token refresh) is Pi's built-in Anthropic transport, and `/login anthropic` keeps its native behavior.

## Install

From the dotfiles repo root:

```sh
pi install ./pi/extensions/anthropic-oauth   # persistent, adds a packages entry to settings.json
pi -e ./pi/extensions/anthropic-oauth        # one-off run
```

## Config

Optional global file at `<agentDir>/extensions/pi-anthropic-auth/config.json` (`agentDir` is `~/.pi/agent` unless `PI_CODING_AGENT_DIR` is set). There is no project-level config.

```json
{ "providers": ["anthropic-2", "anthropic-3"] }
```

`anthropic` is always checked first; listed providers follow in file order, trimmed and deduplicated. The file is re-read on every `/anthropic-auth:status`, so edits apply without `/reload`.

Warnings (shown in the report; the notification becomes a warning):

| Warning | Cause |
| --- | --- |
| `invalid JSON: <message>` | File does not parse |
| `expected a JSON object at top level` | Top level is an array, `null`, or a primitive |
| `"providers" must be an array of strings` | `providers` is present but not an array |
| `providers[<i>] must be a non-empty string` | Entry is not a string or is blank (index in the original array) |
| `unknown key "<key>" ignored` | Any key other than `providers` |
| `cannot read file: <message>` | File exists but cannot be read |

Valid parts of a partially invalid config are still used.

## Development

```sh
npm install
npm test        # node:test, native TypeScript stripping
npm run check   # tsc --noEmit
```
