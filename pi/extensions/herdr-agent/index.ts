/**
 * Herdr agent monitor
 *
 * - `/herdr-agents` lists every live Herdr agent (name, kind, status, cwd).
 * - Inside Herdr (HERDR_ENV=1), in the interactive TUI, and not as a
 *   /superagent worker (SUPERAGENT_WORKER unset), polls `herdr agent list`
 *   every 3 s and shows a footer summary of the `sa-*` workers started by the
 *   herdr-delegate skill, plus a warning when a worker becomes blocked.
 *
 * Agent state reporting to Herdr itself is Herdr's own managed integration
 * (~/.pi/agent/extensions/herdr-agent-state.ts, `herdr integration install pi`);
 * this extension only reads.
 */

import { accessSync, constants } from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type AgentStatus = "idle" | "working" | "blocked" | "done" | "unknown";

interface HerdrAgent {
	name?: string;
	agent?: string;
	agent_status: AgentStatus;
	workspace_id: string;
	tab_id: string;
	pane_id: string;
	cwd?: string;
}

const STATUS_KEY = "herdr-sa";
const POLL_MS = 3000;
const WORKER_PREFIX = "sa-";

const listAgents = async (pi: ExtensionAPI): Promise<HerdrAgent[] | null> => {
	const res = await pi.exec("herdr", ["agent", "list"], { timeout: 2500 });
	if (res.code !== 0) return null;
	try {
		const agents = JSON.parse(res.stdout)?.result?.agents;
		return Array.isArray(agents) ? (agents as HerdrAgent[]) : null;
	} catch {
		return null;
	}
};

const summarize = (ctx: ExtensionContext, workers: HerdrAgent[]): string | undefined => {
	if (workers.length === 0) return undefined;
	const count = (...statuses: AgentStatus[]) => workers.filter((a) => statuses.includes(a.agent_status)).length;
	const th = ctx.ui.theme;
	const parts = [
		[count("working"), "accent", "●", "working"],
		[count("blocked"), "warning", "◐", "blocked"],
		[count("idle", "done"), "success", "✓", "ready"],
		[count("unknown"), "dim", "?", "unknown"],
	] as const;
	const text = parts
		.filter(([n]) => n > 0)
		.map(([n, color, icon, label]) => th.fg(color, `${icon} ${n} ${label}`))
		.join(" · ");
	return `sa ${text}`;
};

export default function (pi: ExtensionAPI) {
	let timer: NodeJS.Timeout | undefined;
	let inFlight = false;
	const lastStatus = new Map<string, AgentStatus>();

	const stop = (ctx: ExtensionContext) => {
		clearInterval(timer);
		timer = undefined;
		lastStatus.clear();
		ctx.ui.setStatus(STATUS_KEY, undefined);
	};

	const poll = async (ctx: ExtensionContext) => {
		if (inFlight) return;
		inFlight = true;
		try {
			const agents = await listAgents(pi);
			if (!timer) return; // shut down while the command was running
			if (!agents) {
				ctx.ui.setStatus(STATUS_KEY, undefined);
				return;
			}
			const workers = agents.filter((a) => a.name?.startsWith(WORKER_PREFIX));
			const seen = new Set<string>();
			for (const a of workers) {
				const name = a.name as string;
				seen.add(name);
				const prev = lastStatus.get(name);
				if (a.agent_status === "blocked" && prev !== "blocked") {
					ctx.ui.notify(`herdr: ${name} is blocked — herdr agent read ${name}`, "warning");
				}
				lastStatus.set(name, a.agent_status);
			}
			for (const name of lastStatus.keys()) if (!seen.has(name)) lastStatus.delete(name);
			ctx.ui.setStatus(STATUS_KEY, summarize(ctx, workers));
		} finally {
			inFlight = false;
		}
	};

	pi.on("session_start", async (_event, ctx) => {
		if (timer) return;
		if (process.env.HERDR_ENV !== "1" || process.env.SUPERAGENT_WORKER || ctx.mode !== "tui") return;
		// pi.exec resolves (code 1) instead of throwing when the binary is missing,
		// so check PATH once up front rather than polling a missing binary forever.
		const herdrOnPath = (process.env.PATH ?? "").split(path.delimiter).some((dir) => {
			if (!dir) return false;
			try {
				accessSync(path.join(dir, "herdr"), constants.X_OK);
				return true;
			} catch {
				return false;
			}
		});
		if (!herdrOnPath) return;
		timer = setInterval(() => void poll(ctx), POLL_MS);
		void poll(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		stop(ctx);
	});

	pi.registerCommand("herdr-agents", {
		description: "List Herdr agents (name, status, location)",
		handler: async (_args, ctx) => {
			if (process.env.HERDR_ENV !== "1") {
				ctx.ui.notify("Not inside Herdr (HERDR_ENV!=1)", "warning");
				return;
			}
			const agents = await listAgents(pi);
			if (!agents) {
				ctx.ui.notify("herdr agent list failed", "error");
				return;
			}
			const lines = agents.map(
				(a) => `${a.name ?? a.pane_id}  ${a.agent ?? "?"}  ${a.agent_status}  ${a.cwd ?? ""}`.trimEnd(),
			);
			ctx.ui.notify(lines.length > 0 ? lines.join("\n") : "No Herdr agents.", "info");
		},
	});
}
