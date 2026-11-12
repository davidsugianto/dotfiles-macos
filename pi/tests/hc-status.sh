#!/usr/bin/env bash
# Tests pi/extensions/hc-status.ts (OSC 7501 status for the Herdr desktop app).
# Needs Node with native TypeScript type-stripping (>= 22.18): the extension is
# imported as a .ts file, its pi imports being `import type` only.
# HC_STATUS_EXT overrides the extension path (used to mutation-check this test).
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
settings="$repo_root/pi/settings.json"
ext="${HC_STATUS_EXT:-$repo_root/pi/extensions/hc-status.ts}"

if ! command -v node >/dev/null 2>&1 || [[ "$(node -p 'Boolean(process.features.typescript)' 2>/dev/null)" != "true" ]]; then
	echo "hc-status test needs Node >= 22.18 (native TypeScript type-stripping); found: $(node --version 2>/dev/null || echo none)" >&2
	exit 1
fi

# Pure builder: exact sequences, field gating, clamping and truncation.
HC_EXT="$ext" node --input-type=module -e '
import assert from "node:assert/strict";
const { buildStatus, CLEAR } = await import(process.env.HC_EXT);
const b64 = (s) => Buffer.from(s, "utf8").toString("base64");

assert.equal(buildStatus({ state: "working", msg: "Working" }), `\x1b]7501;state=working:app=pi:msg=${b64("Working")}\x1b\\`);
assert.equal(buildStatus({ state: "idle" }), "\x1b]7501;state=idle:app=pi\x1b\\");

assert.ok(buildStatus({ state: "blocked", kind: "question", msg: "Needs input" }).includes(":kind=question"));
assert.ok(!buildStatus({ state: "working", kind: "question" }).includes("kind="));
assert.ok(!buildStatus({ state: "idle", kind: "auth" }).includes("kind="));

assert.ok(buildStatus({ state: "working", progress: 150 }).includes(":progress=100"));
assert.ok(buildStatus({ state: "working", progress: -5 }).includes(":progress=0"));
assert.ok(!buildStatus({ state: "idle", progress: 50 }).includes("progress="));

const long = "a".repeat(5000);
assert.ok(buildStatus({ state: "working", msg: long }).includes(`:msg=${b64("a".repeat(2048))}\x1b`));
assert.ok(buildStatus({ state: "working", title: long }).includes(`:title=${b64("a".repeat(192))}\x1b`));

assert.equal(CLEAR, "\x1b]7501;state=clear:app=pi\x1b\\");
assert.ok(CLEAR.startsWith("\x1b]7501;state=clear"));
'

# Extension wiring: env gating and event -> sequence mapping, with a fake pi.
HC_EXT="$ext" node --input-type=module -e '
import assert from "node:assert/strict";
const { default: register, buildStatus, CLEAR } = await import(process.env.HC_EXT);
const IDLE = buildStatus({ state: "idle", msg: "Idle" });
const WORKING = buildStatus({ state: "working", msg: "Working" });
const BLOCKED = buildStatus({ state: "blocked", kind: "question", msg: "Needs input" });

// Load the extension under a given env; returns the handlers and the writes it made.
const load = (env) => {
	for (const k of ["HC_TERMINAL_SOCKET", "HERDR_ENV"]) delete process.env[k];
	Object.assign(process.env, env);
	const handlers = new Map();
	const on = (name, fn) => handlers.set(name, fn);
	register({ on, events: { on } });
	const writes = [];
	const realWrite = process.stdout.write;
	const fire = (name, ...args) => {
		process.stdout.write = (chunk) => (writes.push(String(chunk)), true);
		try { return handlers.get(name)?.(...args); } finally { process.stdout.write = realWrite; }
	};
	return { handlers, writes, fire };
};
const tui = (idle = true) => ({ mode: "tui", isIdle: () => idle });

// Gating: only the desktop app (HC_TERMINAL_SOCKET set, HERDR_ENV not 1) registers anything.
assert.equal(load({}).handlers.size, 0, "no HC_TERMINAL_SOCKET");
assert.equal(load({ HC_TERMINAL_SOCKET: "/s", HERDR_ENV: "1" }).handlers.size, 0, "inside the herdr TUI");
assert.ok(load({ HC_TERMINAL_SOCKET: "/s" }).handlers.size > 0, "desktop app");

// Non-TUI modes (rpc/print/json) never report.
{
	const t = load({ HC_TERMINAL_SOCKET: "/s" });
	t.fire("session_start", {}, { mode: "rpc", isIdle: () => true });
	t.fire("agent_start", {}, tui());
	t.fire("agent_settled", {}, tui());
	assert.deepEqual(t.writes, []);
}

// Normal turn, with dedupe and settle gating.
{
	const t = load({ HC_TERMINAL_SOCKET: "/s" });
	t.fire("session_start", {}, tui());
	t.fire("agent_start", {}, tui(false));
	t.fire("agent_start", {}, tui(false));
	t.fire("agent_settled", {}, tui(false)); // not idle yet: no report
	assert.deepEqual(t.writes, [IDLE, WORKING], "settled while not idle must not report");
	t.fire("agent_settled", {}, tui(true));
	assert.deepEqual(t.writes, [IDLE, WORKING, IDLE]);
}

// Reload while a turn is running starts as working.
{
	const t = load({ HC_TERMINAL_SOCKET: "/s" });
	t.fire("session_start", {}, tui(false));
	assert.deepEqual(t.writes, [WORKING]);
}

// herdr:blocked (Herdr convention) overrides, and releases to the underlying state.
{
	const t = load({ HC_TERMINAL_SOCKET: "/s" });
	t.fire("session_start", {}, tui());
	t.fire("agent_start", {}, tui(false));
	t.fire("herdr:blocked", { active: true, label: "x" });
	t.fire("herdr:blocked", { active: true, label: "y" });
	t.fire("herdr:blocked", { active: false });
	assert.deepEqual(t.writes, [IDLE, WORKING, BLOCKED], "still blocked: one of two released");
	t.fire("herdr:blocked", { active: false });
	t.fire("herdr:blocked", { active: false }); // extra release never goes negative
	assert.deepEqual(t.writes, [IDLE, WORKING, BLOCKED, WORKING]);
}

// Shutdown clears the status and silences later events.
{
	const t = load({ HC_TERMINAL_SOCKET: "/s" });
	t.fire("session_start", {}, tui());
	t.fire("session_shutdown", {});
	t.fire("agent_start", {}, tui(false));
	assert.deepEqual(t.writes, [IDLE, CLEAR]);
}
'

# Registered exactly once.
jq -e '.extensions | map(select(endswith("hc-status.ts"))) | length == 1' "$settings" >/dev/null

echo ok
