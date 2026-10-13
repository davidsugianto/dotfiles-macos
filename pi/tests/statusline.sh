#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
settings="$repo_root/pi/settings.json"
ext="$repo_root/pi/extensions/statusline"

fail() { echo "FAIL: $*" >&2; exit 1; }

# Hermetic git: a global/system config (commit.gpgsign, init.defaultBranch, core.fsmonitor)
# must not change what these checks see.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
real_git="$(command -v git)" || fail "need git"

jq -e '
  (.extensions | any(endswith("pi/extensions/statusline"))) and
  ((.packages // []) | all(test("statusline-pi") | not))
' "$settings" >/dev/null || fail "pi/settings.json must load pi/extensions/statusline and not list statusline-pi"

for f in index.ts format.ts; do
  [ -f "$ext/$f" ] || fail "missing pi/extensions/statusline/$f"
done

if grep -q 'npm:statusline-pi' "$repo_root/setup.sh"; then
  fail "setup.sh still mentions npm:statusline-pi"
fi

if command -v bun >/dev/null 2>&1; then
  runner=(bun)
elif command -v node >/dev/null 2>&1; then
  runner=(node --experimental-strip-types --no-warnings)
else
  fail "need bun or node to run format.ts checks"
fi

tmp="$(mktemp -d "${TMPDIR:-/tmp}/statusline-check.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
script="$tmp/format.mjs"
cat >"$script" <<JS
import * as f from "file://$ext/format.ts";
const { stripAnsi, formatTokens, levelColor, renderBar, visibleLength, rolesEnabledFrom, buildLine2 } = f;
const errs = [];
const eq = (name, got, want) => { if (got !== want) errs.push(name + ": got " + JSON.stringify(got) + ", want " + JSON.stringify(want)); };
for (const n of ["stripAnsi", "formatTokens", "levelColor", "renderBar", "visibleLength", "rolesEnabledFrom", "buildLine2"]) {
  if (typeof f[n] !== "function") errs.push("missing export " + n);
}
if (!errs.length) {
  eq("renderBar(6)", stripAnsi(renderBar(6)), "▰▱▱▱▱▱▱▱▱▱");
  eq("renderBar(42)", stripAnsi(renderBar(42)), "▰▰▰▰▱▱▱▱▱▱");
  eq("renderBar(100,5)", stripAnsi(renderBar(100, 5)), "▰▰▰▰▰");
  eq("formatTokens(60000)", formatTokens(60000), "60k");
  eq("formatTokens(1000000)", formatTokens(1000000), "1.0M");
  eq("formatTokens(922000)", formatTokens(922000), "922k");
  const lo = levelColor(10, 50, 80), mid = levelColor(60, 50, 80), hi = levelColor(90, 50, 80);
  if (lo === mid || lo === hi || mid === hi) errs.push("levelColor must differ across low/mid/high: " + JSON.stringify([lo, mid, hi]));

  // pi-model-roles publishes live state as the "model-roles" status.
  eq("rolesEnabledFrom(enabled)", rolesEnabledFrom("roles:auto-selector=enabled cekat/x:high"), true);
  eq("rolesEnabledFrom(disabled)", rolesEnabledFrom("roles:auto-selector=disabled cekat/x:high"), false);
  eq("rolesEnabledFrom(ansi)", rolesEnabledFrom("\x1b[32mroles:auto-selector=enabled\x1b[0m"), true);
  eq("rolesEnabledFrom(undefined)", rolesEnabledFrom(undefined), false);

  // buildLine2 degrades with width: CPU/MEM, then MCP, then a 5-cell bar.
  const base = { ctxPct: 6, ctxUsed: 60000, ctxWindow: 1000000, cpu: 7, mem: 76, rolesEnabled: true, mcpCount: 3 };
  const l2 = (d, w) => stripAnsi(buildLine2(d, w));
  const has = (name, s, sub, want) => { if (s.includes(sub) !== want) errs.push(name + ": " + JSON.stringify(s) + (want ? " lacks " : " must not contain ") + JSON.stringify(sub)); };
  const wide = l2(base, 120);
  has("l2@120 ctx", wide, "ctx ▰▱▱▱▱▱▱▱▱▱ 6% 60k/1.0M", true);
  has("l2@120 sys", wide, "CPU 7% MEM 76%", true);
  has("l2@120 roles", wide, "roles ● auto · MCP 3", true);
  const noSys = l2(base, 60);
  has("l2@60 sys", noSys, "CPU", false);
  has("l2@60 mcp", noSys, "MCP 3", true);
  const noMcp = l2(base, 45);
  has("l2@45 mcp", noMcp, "MCP", false);
  has("l2@45 roles", noMcp, "roles ● auto", true);
  has("l2@45 bar", noMcp, "▰▱▱▱▱▱▱▱▱▱", true);
  const small = l2(base, 40);
  has("l2@40 5-cell bar", small, "ctx ▱▱▱▱▱ 6%", true);
  has("l2@40 not 10-cell", small, "▱▱▱▱▱▱", false);
  for (const [w, line] of [[120, wide], [60, noSys], [45, noMcp], [40, small]]) {
    if (line.length > w) errs.push("l2@" + w + " is " + line.length + " wide");
  }
  has("l2 roles off", l2({ ...base, rolesEnabled: false }, 120), "roles ○ off", true);
}
if (errs.length) { console.error(errs.join("\n")); process.exit(1); }
JS
"${runner[@]}" "$script" || fail "format.ts checks failed"

# git.ts: reading status must not take index locks or run a repo's fsmonitor hook.
cat >"$tmp/git.mjs" <<'JS'
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { chmodSync, existsSync, readFileSync, utimesSync, writeFileSync } from "node:fs";
const { readGit } = await import("file://" + process.env.EXT + "/git.ts");

const repo = process.env.REPO;
const git = (...a) => execFileSync("git", ["-c", "user.name=t", "-c", "user.email=t@t", ...a], { cwd: repo, stdio: "ignore" });
git("init", "-q", ".");
writeFileSync(repo + "/f", "a\n");
git("add", "f");
git("commit", "-qm", "init");
const errs = [];

// stat-only change: a plain `git status` would refresh and rewrite .git/index
const future = new Date(Date.now() + 60_000);
utimesSync(repo + "/f", future, future);
const sha = () => createHash("sha1").update(readFileSync(repo + "/.git/index")).digest("hex");
const before = sha();
const info = readGit(repo);
if (sha() !== before) errs.push("readGit rewrote .git/index (needs GIT_OPTIONAL_LOCKS=0)");
if (info.dirty !== 0) errs.push("expected a clean tree, got dirty=" + info.dirty);

// a repo-configured fsmonitor command must not run
writeFileSync(repo + "/hook.sh", "#!/bin/sh\ntouch " + repo + "/marker\n");
chmodSync(repo + "/hook.sh", 0o755);
git("config", "core.fsmonitor", repo + "/hook.sh");
readGit(repo);
if (existsSync(repo + "/marker")) errs.push("readGit executed the repo's core.fsmonitor command");

if (errs.length) { console.error(errs.join("\n")); process.exit(1); }
JS
repo="$tmp/repo"; mkdir -p "$repo"
EXT="$ext" REPO="$repo" "${runner[@]}" "$tmp/git.mjs" || fail "git.ts checks failed"

# index.ts end-to-end with a fake pi: file edits made by the agent must show in the dirty
# count promptly after tool_result, not up to 5s later. An isolated result after idle
# refreshes at once; a burst is throttled to one git read per second plus a trailing
# re-render (so up to ~1s of delay). Needs bun's module plugin to stub pi-tui, so it is
# skipped under node.
if [ "${runner[0]}" = bun ]; then
cat >"$tmp/footer.mjs" <<'JS'
import { plugin } from "bun";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

plugin({
  name: "stub-pi-tui",
  setup(build) {
    build.module("@earendil-works/pi-tui", () => ({ exports: { truncateToWidth: (s) => s }, loader: "object" }));
  },
});

const ext = process.env.EXT;
const repo = process.env.REPO;
const { stripAnsi } = await import("file://" + ext + "/format.ts");
const mod = await import("file://" + ext + "/index.ts");

const handlers = {};
let factory;
let branchCalls = 0;
const branch = [];
const profileFile = join(process.env.HOME, ".pi", "profiles", ".active");
const pi = { on: (e, h) => { handlers[e] = h; }, registerCommand() {}, getThinkingLevel: () => "high" };
const ctx = {
  hasUI: true,
  cwd: repo,
  model: { id: "p/m", name: "m", contextWindow: 1000000 },
  getContextUsage: () => ({ tokens: 1000 }),
  sessionManager: { getBranch: () => { branchCalls++; return branch; } },
  ui: { setFooter: (f) => { factory = f; }, notify() {} },
};
const statuses = new Map([["model-roles", "roles:auto-selector=enabled"], ["mcp", "MCP: 3 servers"], ["other", "keep-me"], ["profile", "🏢 Alpha label"]]);
const footerData = { onBranchChange: () => () => {}, getGitBranch: () => "main", getExtensionStatuses: () => statuses };
mod.default(pi);
await handlers.session_start({}, ctx);
let renders = 0;
const footer = factory({ requestRender() { renders++; } }, {}, footerData);
const lines = () => footer.render(200).map(stripAnsi);
const errs = [];

const gitCalls = () => readFileSync(process.env.GIT_LOG, "utf8").split("\n").filter((l) => l.includes("rev-parse --abbrev-ref HEAD")).length;
const first = lines();
if (/●/.test(first[0])) errs.push("clean repo should show no dirty marker: " + first[0]);
if (!first[1].includes("roles ● auto")) errs.push("roles segment should follow the live status: " + first[1]);
if (first.some((l) => l.includes("MCP: 3 servers"))) errs.push("folded mcp status was printed again");
if (!first.includes("keep-me")) errs.push("unrelated extension statuses must still be shown");
if (first.some((l) => l.includes("Alpha label"))) errs.push("folded profile status was printed again");

// Cost, profile and MCP count are not recomputed on every render: cost follows
// message_end, profile/MCP follow the git refresh cadence.
if (!first[0].includes("profile:alpha")) errs.push("profile segment should read ~/.pi/profiles/.active: " + first[0]);
if (!first[1].includes("MCP 2")) errs.push("MCP count should come from mcp-adapter.json: " + first[1]);
const callsAfterFirst = branchCalls;
for (let i = 0; i < 10; i++) lines();
if (branchCalls !== callsAfterFirst) errs.push("10 renders walked the session branch " + (branchCalls - callsAfterFirst) + " times; expected cost to be cached");
writeFileSync(profileFile, "gamma\n");
if (!lines()[0].includes("profile:alpha")) errs.push("profile was re-read on a plain render; expected it to follow the git refresh cadence");
// pi-profile writes .active, then publishes its "profile" status: that change must refresh the name at once.
statuses.set("profile", "🏢 Gamma label");
if (!lines()[0].includes("profile:gamma")) errs.push("profile not refreshed when pi-profile's status changed: " + lines()[0]);
branch.push({ type: "message", message: { role: "assistant", usage: { cost: { total: 0.5 } } } });
await handlers.message_end({}, ctx);
if (!lines()[0].includes("$0.50")) errs.push("cost not updated after message_end: " + lines()[0]);

// Let the startup system-stats sample finish so its re-render cannot mask the trailing one below.
await new Promise((r) => setTimeout(r, 400));
// A burst of tool results (an agent editing files) must not run git once per result...
writeFileSync(repo + "/new.txt", "x\n");
const baseline = gitCalls();
for (let i = 0; i < 5; i++) {
  await handlers.tool_result({}, ctx);
  lines();
}
if (gitCalls() - baseline > 1) errs.push("tool_result burst ran git " + (gitCalls() - baseline) + " times; expected it to be throttled");

// ...but the dirty count must still catch up shortly after, via a trailing re-render.
const rendersBefore = renders;
await new Promise((r) => setTimeout(r, 1500));
if (renders === rendersBefore) errs.push("no trailing re-render was requested after the tool_result burst");
const second = lines();
if (!second[0].includes("●1")) errs.push("dirty count not refreshed after tool_result burst: " + second[0]);
if (gitCalls() - baseline > 2) errs.push("expected at most 2 git reads after the burst, got " + (gitCalls() - baseline));

// An isolated tool result after idle (cache older than the 1s throttle) refreshes immediately,
// with no trailing timer. Total runtime stays well under the 5s interval that also clears the cache.
await new Promise((r) => setTimeout(r, 1200));
writeFileSync(repo + "/idle.txt", "y\n");
await handlers.tool_result({}, ctx);
const idle = lines();
if (!idle[0].includes("●2")) errs.push("dirty count not refreshed immediately after an idle tool_result: " + idle[0]);
if (!idle[0].includes("profile:gamma")) errs.push("profile not picked up on the git refresh: " + idle[0]);

// After shutdown, a pending trailing timer (fired while the cache is fresh) must not render.
await handlers.tool_result({}, ctx);
await handlers.session_shutdown({}, ctx);
const rendersAtShutdown = renders;
await new Promise((r) => setTimeout(r, 1300));
if (renders !== rendersAtShutdown) errs.push("requestRender was called " + (renders - rendersAtShutdown) + " time(s) after session_shutdown");
if (errs.length) { console.error(errs.join("\n")); process.exit(1); }
process.exit(0);
JS
rm -rf "$repo"; mkdir -p "$repo"
git -C "$repo" init -q . && git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
# git shim: logs every invocation, then runs the real git.
mkdir -p "$tmp/shim"
printf '#!/bin/sh\necho "$@" >>"$GIT_LOG"\nexec "$REAL_GIT" "$@"\n' >"$tmp/shim/git"
chmod +x "$tmp/shim/git"; : >"$tmp/git.log"
mkdir -p "$tmp/home/.pi/profiles" "$tmp/home/.pi/agent"
printf 'alpha\n' >"$tmp/home/.pi/profiles/.active"
printf '{"mcpServers":{"a":{},"b":{}}}\n' >"$tmp/home/.pi/agent/mcp-adapter.json"
HOME="$tmp/home" PATH="$tmp/shim:$PATH" REAL_GIT="$real_git" GIT_LOG="$tmp/git.log" EXT="$ext" REPO="$repo" bun "$tmp/footer.mjs" || fail "index.ts footer checks failed"
else
  footer_skipped=" (index.ts footer checks skipped: needs bun)"
  echo "skipped index.ts footer checks (needs bun)"
fi

echo "statusline checks passed${footer_skipped:-}"
