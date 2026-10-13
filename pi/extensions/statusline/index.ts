/**
 * Custom footer/statusline, styled like claude/scripts/claude-statusline.
 * Fixed Catppuccin Mocha truecolor values (see format.ts), not pi theme colours.
 *
 * - Line 1: repo branch ●dirty ↑ahead ↓behind │ model · thinking │ $cost │ profile
 * - Line 2: ctx bar │ CPU/MEM │ roles · MCP
 * - `/statusline [on|off|toggle]` mounts/unmounts the footer for the session.
 */

import { execFile } from "node:child_process";
import { readFileSync } from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { buildLine1, buildLine2, rolesEnabledFrom, shortModel } from "./format.ts";
import { type GitInfo, readGit } from "./git.ts";

const REFRESH_MS = 5_000;
// Tool results mark git stale, but it is re-read at most this often (an agent can fire
// many in a burst, and readGit is synchronous on the render path).
const GIT_MIN_INTERVAL_MS = 1_000;
const HOME = os.homedir();
const PROFILE_FILE = path.join(HOME, ".pi", "profiles", ".active");
const MCP_CONFIG = path.join(HOME, ".pi", "agent", "mcp-adapter.json");

function readProfile(): string {
	try {
		return readFileSync(PROFILE_FILE, "utf8").trim() || "default";
	} catch {
		return "default";
	}
}

// Statuses this footer already shows itself (roles and MCP on line 2, profile on line 1);
// drop the duplicates.
const FOLDED_STATUSES = new Set(["model-roles", "mcp", "profile"]);

function readMcpCount(): number | undefined {
	try {
		const json = JSON.parse(readFileSync(MCP_CONFIG, "utf8"));
		return Object.keys(json?.mcpServers ?? {}).length;
	} catch {
		return undefined;
	}
}

function run(cmd: string, args: string[]): Promise<string | undefined> {
	return new Promise((resolve) => {
		try {
			execFile(cmd, args, { encoding: "utf8", timeout: 3_000 }, (err, stdout) => resolve(err ? undefined : stdout));
		} catch {
			resolve(undefined);
		}
	});
}

/** Same maths as claude-statusline: ps %cpu sum / ncpu (cap 100); vm_stat active+wired+compressor / memsize. */
async function sampleSystem(): Promise<{ cpu?: number; mem?: number }> {
	const out: { cpu?: number; mem?: number } = {};
	const ps = await run("ps", ["-A", "-o", "%cpu="]);
	if (ps !== undefined) {
		const sum = ps.split("\n").reduce((a, l) => a + (Number.parseFloat(l) || 0), 0);
		out.cpu = Math.min(100, Math.floor(sum / Math.max(1, os.cpus().length)));
	}
	const vm = await run("vm_stat", []);
	const total = os.totalmem();
	if (vm !== undefined && total > 0) {
		const pageSize = Number.parseInt(/page size of (\d+)/.exec(vm)?.[1] ?? "", 10) || 4096;
		const pages = (label: string): number =>
			Number.parseInt(new RegExp(`${label}:\\s*(\\d+)`).exec(vm)?.[1] ?? "0", 10);
		const used = pages("Pages active") + pages("Pages wired down") + pages("Pages occupied by compressor");
		out.mem = Math.min(100, Math.floor((used * pageSize * 100) / total));
	}
	return out;
}

interface Usage {
	input?: number;
	output?: number;
	cacheRead?: number;
	cacheWrite?: number;
	cost?: { total?: number };
}

function sessionCost(ctx: ExtensionContext): number | undefined {
	try {
		const rates = (ctx.model as { cost?: Record<string, number> } | undefined)?.cost;
		let total = 0;
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type !== "message") continue;
			const msg = entry.message as unknown as { role: string; usage?: Usage };
			if (msg.role !== "assistant" || !msg.usage) continue;
			const u = msg.usage;
			const reported = u.cost?.total ?? 0;
			if (reported > 0) {
				total += reported;
			} else if (rates) {
				total +=
					((rates.input ?? 0) / 1e6) * (u.input ?? 0) +
					((rates.output ?? 0) / 1e6) * (u.output ?? 0) +
					((rates.cacheRead ?? 0) / 1e6) * (u.cacheRead ?? 0) +
					((rates.cacheWrite ?? 0) / 1e6) * (u.cacheWrite ?? 0);
			}
		}
		return total;
	} catch {
		return undefined;
	}
}

export default function (pi: ExtensionAPI): void {
	let timer: ReturnType<typeof setInterval> | undefined;
	let requestRender: (() => void) | undefined;
	let gitInfo: GitInfo | undefined;
	let gitStale = false;
	// Not recomputed per render: cost on mount/message_end/model_select/tick, profile and MCP count with the git refresh.
	let cost: number | undefined;
	let profile = "default";
	let mcpCount: number | undefined;
	let profileStatus: string | undefined;
	let gitTrailing: ReturnType<typeof setTimeout> | undefined;
	let sys: { cpu?: number; mem?: number } = {};
	let mounted = false;

	function clearTimers(): void {
		if (timer) clearInterval(timer);
		timer = undefined;
		if (gitTrailing) clearTimeout(gitTrailing);
		gitTrailing = undefined;
	}

	function stopTimer(): void {
		clearTimers();
		requestRender = undefined;
	}

	function refreshSystem(): void {
		void sampleSystem().then((s) => {
			sys = s;
			requestRender?.();
		});
	}

	function mount(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;
		gitInfo = undefined;
		cost = sessionCost(ctx);
		ctx.ui.setFooter((tui, _theme, footerData) => {
			const unsubscribe = footerData.onBranchChange(() => {
				gitInfo = undefined;
				tui.requestRender();
			});
			requestRender = () => tui.requestRender();
			return {
				dispose() {
					unsubscribe();
				},
				invalidate() {
					tui.requestRender();
				},
				render(width: number): string[] {
					let g = gitInfo;
					const age = g ? Date.now() - g.at : Number.POSITIVE_INFINITY;
					if (!g || age > REFRESH_MS || (gitStale && age >= GIT_MIN_INTERVAL_MS)) {
						g = gitInfo = readGit(ctx.cwd);
						gitStale = false;
						profile = readProfile();
						mcpCount = readMcpCount();
					}
					const extStatuses = footerData.getExtensionStatuses?.() as Map<string, string> | undefined;
					// pi-profile writes ~/.pi/profiles/.active first and publishes its "profile" status
					// last, so a change in that status text is the cue to re-read the name.
					const nextProfileStatus = extStatuses?.get("profile");
					if (nextProfileStatus !== profileStatus) {
						profileStatus = nextProfileStatus;
						profile = readProfile();
					}
					const usage = ctx.getContextUsage?.();
					const window = ctx.model?.contextWindow;
					const used = usage?.tokens ?? undefined;
					const known = typeof used === "number" && typeof window === "number" && window > 0;
					const thinking = pi.getThinkingLevel?.();
					const line1 = buildLine1(
						{
							repo: path.basename(ctx.cwd) || ctx.cwd,
							branch: g.branch ?? footerData.getGitBranch?.() ?? undefined,
							dirty: g.dirty,
							ahead: g.ahead,
							behind: g.behind,
							model: shortModel(ctx.model?.name || ctx.model?.id),
							thinking: thinking || undefined,
							cost,
							profile,
						},
						width,
					);
					const line2 = buildLine2(
						{
							ctxPct: known ? Math.min(100, (used / window) * 100) : undefined,
							ctxUsed: known ? used : undefined,
							ctxWindow: known ? window : undefined,
							cpu: sys.cpu,
							mem: sys.mem,
							rolesEnabled: rolesEnabledFrom(extStatuses?.get("model-roles")),
							mcpCount,
						},
						width,
					);
					const statuses = Array.from(extStatuses?.entries() ?? [])
						.filter(([key]) => !FOLDED_STATUSES.has(key))
						.map(([, st]) => truncateToWidth(st, width));
					return [truncateToWidth(line1, width), truncateToWidth(line2, width), ...statuses];
				},
			};
		});
		mounted = true;
		clearTimers();
		refreshSystem();
		timer = setInterval(() => {
			gitInfo = undefined;
			cost = sessionCost(ctx);
			refreshSystem();
			requestRender?.();
		}, REFRESH_MS);
	}

	function unmount(ctx: ExtensionContext): void {
		stopTimer();
		mounted = false;
		if (ctx.hasUI) ctx.ui.setFooter(undefined);
	}

	const rerender = async (): Promise<void> => {
		requestRender?.();
	};
	const recost = async (_event: unknown, ctx: ExtensionContext): Promise<void> => {
		cost = sessionCost(ctx);
		requestRender?.();
	};

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.hasUI) mount(ctx);
	});
	pi.on("session_shutdown", async () => {
		stopTimer();
		mounted = false;
	});
	pi.on("model_select", recost);
	pi.on("thinking_level_select", rerender);
	pi.on("message_end", recost);
	// Tools (edit/write/bash) change the working tree, so mark the cached git state stale
	// rather than waiting for the next 5s tick. render() re-reads it at most once per
	// GIT_MIN_INTERVAL_MS; a single trailing re-render picks up whatever the throttle held back.
	pi.on("tool_result", async () => {
		gitStale = true;
		const age = gitInfo ? Date.now() - gitInfo.at : GIT_MIN_INTERVAL_MS;
		if (age < GIT_MIN_INTERVAL_MS && !gitTrailing) {
			gitTrailing = setTimeout(() => {
				gitTrailing = undefined;
				requestRender?.();
			}, GIT_MIN_INTERVAL_MS - age + 25);
		}
		requestRender?.();
	});

	pi.registerCommand("statusline", {
		description: "Toggle the custom statusline footer: /statusline [on|off|toggle]",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) return;
			const arg = (args ?? "").trim().toLowerCase();
			if (arg !== "" && arg !== "on" && arg !== "off" && arg !== "toggle") {
				ctx.ui.notify("Usage: /statusline [on|off|toggle]", "error");
				return;
			}
			const want = arg === "on" ? true : arg === "off" ? false : !mounted;
			if (want) mount(ctx);
			else unmount(ctx);
			ctx.ui.notify(`statusline ${want ? "on" : "off"}`, "info");
		},
	});
}
