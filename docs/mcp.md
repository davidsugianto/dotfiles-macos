# MCP servers

Datadog, Jira, Slack and Cloudflare MCP servers for omp, pi and Claude Code. Back to the [README](../README.md).

Server entries live in `omp/mcp.json`, `pi/mcp-adapter.json` and `claude/mcp.json`. Keep them identical across all three.

## Datadog MCP

omp and pi both talk to Datadog's hosted
[MCP server](https://docs.datadoghq.com/mcp_server/setup/) (logs, metrics,
traces, monitors, incidents, dashboards) over Streamable HTTP, defined as a
`datadog` server in `omp/mcp.json` (→ `~/.omp/agent/mcp.json`, native omp
MCP) and `pi/mcp-adapter.json` (→ `~/.pi/agent/mcp-adapter.json`, read by the
[pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) package —
pi has no built-in MCP), and `claude/mcp.json` for Claude Code. Each agent has its
own loader, so keep the server entries identical across all three.

Claude Code keeps its user-scope servers in `~/.claude.json` (runtime state,
never linked), so `claude/mcp.json` is registered with
`claude-mcp-sync` (`claude mcp add-json -s user`, run by `setup.sh`;
`--force` re-adds after editing). Login: `/mcp` → server → Authenticate.

Auth is browser OAuth — the same Datadog login you use in the web app
(e.g. Google SSO); no API/application keys. Datadog supports dynamic client
registration and accepts omp's/pi's localhost callbacks, so no org
allow-listing is needed. Tokens are stored per agent (omp: its `agent.db`;
pi: the macOS keychain), never in this repo, and refresh automatically.

The endpoint is pinned to the org's site, US5
(`https://mcp.us5.datadoghq.com/v1/mcp`, login at
`us5.datadoghq.com`), directly in both files — not via an env var, so omp/pi
launched from anywhere (Orca, an old shell) always hit the right site. For
another site swap the host (`mcp.datadoghq.com` = US1, `mcp.us3.datadoghq.com`,
`mcp.datadoghq.eu`, `mcp.ap1.datadoghq.com`, …) in both files and re-login.

First login, once per agent:

- omp: `/mcp reauth datadog` → browser opens → sign in → `/mcp test datadog`.
- pi: `/mcp-auth datadog` (or `/mcp`, Enter on the server) → browser → sign in.
- Claude Code: `/mcp` → `datadog` → Authenticate → browser → sign in.
  Servers connect lazily on first tool call — the agent finds tools via
  `mcp({ search: "logs" })`.

Both agents enable all generally available toolsets with `?toolsets=all`,
including write-capable product toolsets. Datadog permissions still control
which actions the signed-in user can perform. To limit exposure, replace
`all` with a comma-separated list such as `core,alerting,dashboards` in both
files. If your org signs in through a custom subdomain, append
`&subdomain=<name>` too.

## Jira MCP

All three agents also talk to Atlassian's hosted Rovo
[MCP server](https://support.atlassian.com/atlassian-ai-gateway/docs/get-started-with-the-atlassian-remote-mcp-server/)
(`https://mcp.atlassian.com/v1/mcp/authv2`, Streamable HTTP) as a `jira`
server in `omp/mcp.json`, `pi/mcp-adapter.json` and `claude/mcp.json` — keep
the three entries identical. The old `/v1/sse` endpoint is deprecated.

Auth is browser OAuth 2.1 with your Atlassian Cloud login (incl. SSO). Like
Datadog (unlike Slack) it supports dynamic client registration, so there is no
app, client ID/secret, API token or env var. Tokens are stored per agent (omp:
`agent.db`; pi and Claude Code: the macOS keychain), never in this repo. On
first login you pick the Atlassian site to grant access to.

The one server exposes Jira **and** Confluence and Compass tools (scopes
include read/write:jira-work, Confluence page/comment read/write, Compass).
There is no toolset filter like Datadog's `?toolsets=`; the signed-in user's
Atlassian permissions bound what it can do, including writes. An org/site
admin can disable the Rovo MCP server or restrict allowed clients/domains, and
first-time access may need admin approval — if login fails after the browser
step, that is the likely cause.

If an agent's OAuth client can't follow RFC 9728 discovery to
`auth.atlassian.com`, use `https://mcp.atlassian.com/v1/mcp` (legacy
discovery, also DCR) for that agent.

First login, once per agent:

- omp: `/mcp reload`, then `/mcp reauth jira` → browser → approve →
  `/mcp test jira`.
- pi: `/reload`, then `/mcp-auth jira` → browser → approve.
- Claude Code: `claude-mcp-sync` (registers only missing servers; no
  `--force` needed), then `/mcp` → `jira` → Authenticate.

## Slack MCP

omp and pi also talk to Slack's hosted MCP server
(`https://mcp.slack.com/mcp`: search, read channels/threads, send messages,
canvases, lists) as a `slack` server in the same two files as Datadog
(`omp/mcp.json`, `pi/mcp-adapter.json`, `claude/mcp.json`; keep them identical).

Unlike Datadog, Slack does **not** support dynamic client registration — it
needs a pre-registered Slack app (internal or directory-published) with a
fixed client ID/secret. Client credentials are never committed: both files
reference `${SLACK_MCP_CLIENT_ID}` and `${SLACK_MCP_CLIENT_SECRET}`, which you
export in the git-ignored `~/.zshrc.local` (template in
`zsh/.zshrc.local.example`). Tokens are stored per agent like Datadog's
(omp: `agent.db`; pi: macOS keychain).

One-time setup:

1. [api.slack.com/apps](https://api.slack.com/apps) → create an app in your
   workspace → **OAuth & Permissions**:
   - Redirect URL: `http://localhost:3118/callback` (both agents use this
     exact URL via `oauth.redirectUri`; only one can be mid-login at a time).
   - **User Token Scopes** for the tools you want: `search:read.public`,
     `search:read.private`, `search:read.mpim`, `search:read.im`,
     `search:read.files`, `search:read.users`, `channels:history`,
     `groups:history`, `mpim:history`, `im:history`, `channels:read`,
     `groups:read`, `im:read`, `mpim:read`, `users:read`, `users:read.email`,
     `chat:write`, `reactions:read`, `reactions:write`, `canvases:read`,
     `canvases:write`, `lists:read`, `lists:write`, `files:read`,
     `files:write`, `emoji:read`, `channels:write`, `groups:write`,
     `im:write`, `mpim:write`. Drop write scopes for a read-only setup.
   - Slack only allows MCP for internal or directory-published apps; a
     workspace admin may need to approve the app.
2. Copy Client ID/Secret (**Basic Information**) into `~/.zshrc.local` as
   `SLACK_MCP_CLIENT_ID` / `SLACK_MCP_CLIENT_SECRET`, then `exec zsh`.
3. Login, once per agent (restart the agent so it sees the env vars):
   - omp: `/mcp reauth slack` → browser → approve → `/mcp test slack`.
   - pi: `/mcp-auth slack` → browser → approve.
   - Claude Code: `claude-mcp-sync` (it registers Slack only once the env
     vars are set, and hands the secret to Claude via `MCP_CLIENT_SECRET`, which
     stores it in the keychain and not in JSON), then `/mcp` → `slack` → Authenticate.
     Claude's `oauth.callbackPort: 3118` matches the same redirect URL.

## Cloudflare MCP

All three agents also talk to Cloudflare's hosted API
[MCP server](https://github.com/cloudflare/mcp)
(`https://mcp.cloudflare.com/mcp`, Streamable HTTP) as a `cloudflare` server
in `omp/mcp.json`, `pi/mcp-adapter.json` and `claude/mcp.json` — keep the
three entries identical.

Auth is browser OAuth with your Cloudflare login. Dynamic client registration
is supported, so there is no app, API token or env var. At login you pick the
account and permission scopes; if a call needs a scope you didn't grant, the
server asks to re-authorize with it added. Tokens are stored per agent (omp:
`agent.db`; pi and Claude Code: the macOS keychain), never in this repo.

The server runs in code mode by default: the whole Cloudflare API is exposed
through a search tool and an execute tool rather than one tool per endpoint.
Append `?codemode=false` to the URL to disable it — change it in all three
files.

First login, once per agent:

- omp: `/mcp reload`, then `/mcp reauth cloudflare` → browser → approve →
  `/mcp test cloudflare`.
- pi: `/reload`, then `/mcp-auth cloudflare` → browser → approve.
- Claude Code: `claude-mcp-sync` (registers only missing servers), then
  `/mcp` → `cloudflare` → Authenticate.
