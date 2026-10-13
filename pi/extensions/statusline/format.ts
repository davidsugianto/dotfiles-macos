/**
 * Pure formatting helpers for the statusline extension.
 * No runtime imports on purpose: importable from bun/node tests.
 * Colours are fixed Catppuccin Mocha truecolor values (not pi theme colours).
 */

const ESC = "\x1b[";
const rgb = (r: number, g: number, b: number): string => `${ESC}38;2;${r};${g};${b}m`;

export const C = {
	reset: `${ESC}0m`,
	bold: `${ESC}1m`,
	text: rgb(205, 214, 244),
	dim: rgb(108, 112, 134),
	blue: rgb(137, 180, 250),
	mauve: rgb(203, 166, 247),
	peach: rgb(250, 179, 135),
	green: rgb(166, 227, 161),
	yellow: rgb(249, 226, 175),
	red: rgb(243, 139, 168),
	teal: rgb(148, 226, 213),
} as const;

// eslint-disable-next-line no-control-regex
const ANSI_RE = /\x1b\[[0-9;]*m/g;

export function stripAnsi(s: string): string {
	return s.replace(ANSI_RE, "");
}

export function visibleLength(s: string): number {
	return stripAnsi(s).length;
}

/**
 * pi-model-roles publishes its live (per-session, toggleable) state as the
 * "model-roles" extension status ("roles:auto-selector=enabled|disabled ...").
 * config.yaml's `enabled:` is only the default, so it can disagree with what is
 * actually active.
 */
export function rolesEnabledFrom(status: string | undefined): boolean {
	return /auto-selector=(enabled|disabled)/.exec(stripAnsi(status ?? ""))?.[1] === "enabled";
}

export function formatTokens(n: number): string {
	if (n >= 1e6) return `${(n / 1e6).toFixed(1)}M`;
	return `${Math.round(n / 1e3)}k`;
}

export function levelColor(pct: number, warn: number, crit: number): string {
	if (pct >= crit) return C.red;
	if (pct >= warn) return C.yellow;
	return C.green;
}

export function renderBar(pct: number, cells = 10, warn = 50, crit = 80): string {
	const p = Number.isFinite(pct) ? pct : 0;
	const filled = Math.max(0, Math.min(cells, Math.round((p / 100) * cells)));
	return (
		levelColor(p, warn, crit) +
		"▰".repeat(filled) +
		C.dim +
		"▱".repeat(cells - filled) +
		C.reset
	);
}

// ---------------------------------------------------------------------------
// Line builders
// ---------------------------------------------------------------------------

export const SEP = `${C.dim} │ ${C.reset}`;
export const DOT = `${C.dim} · ${C.reset}`;

export interface Line1Data {
	repo: string;
	branch?: string;
	dirty: number;
	ahead: number;
	behind: number;
	model?: string;
	thinking?: string;
	cost?: number;
	profile: string;
}

export interface Line2Data {
	ctxPct?: number;
	ctxUsed?: number;
	ctxWindow?: number;
	cpu?: number;
	mem?: number;
	rolesEnabled: boolean;
	mcpCount?: number;
}

const seg = (color: string, text: string): string => `${color}${text}${C.reset}`;

/** Strip everything up to the last "/" (provider prefix). */
export function shortModel(id: string | undefined): string | undefined {
	if (!id) return undefined;
	const i = id.lastIndexOf("/");
	const s = i >= 0 ? id.slice(i + 1) : id;
	return s || undefined;
}

export function buildLine1(d: Line1Data, width: number): string {
	let git = `${C.bold}${C.blue}${d.repo}${C.reset}`;
	if (d.branch) {
		git += ` ${seg(C.mauve, d.branch)}`;
		if (d.dirty > 0) git += ` ${seg(C.peach, `●${d.dirty}`)}`;
		if (d.ahead > 0) git += ` ${seg(C.green, `↑${d.ahead}`)}`;
		if (d.behind > 0) git += ` ${seg(C.red, `↓${d.behind}`)}`;
	}
	const model = `${seg(C.text, d.model ?? "–")}${DOT}${seg(C.teal, d.thinking ?? "–")}`;
	const cost = seg(C.green, d.cost === undefined ? "–" : `$${d.cost.toFixed(2)}`);
	const profile = seg(C.yellow, `profile:${d.profile}`);

	const variants = [
		[git, model, cost, profile],
		[git, model, cost],
		[git, model],
	];
	for (const v of variants) {
		const line = v.join(SEP);
		if (visibleLength(line) <= width) return line;
	}
	return variants[variants.length - 1].join(SEP);
}

export function buildLine2(d: Line2Data, width: number): string {
	const build = (cells: number, withSys: boolean, withMcp: boolean): string => {
		let ctx: string;
		if (d.ctxPct === undefined) {
			ctx = `${seg(C.dim, "ctx")} ${seg(C.dim, "▱".repeat(cells))} ${seg(C.dim, "–")}`;
		} else {
			const pct = Math.round(d.ctxPct);
			ctx = `${seg(C.dim, "ctx")} ${renderBar(d.ctxPct, cells)} ${seg(levelColor(d.ctxPct, 50, 80), `${pct}%`)}`;
			if (d.ctxUsed !== undefined && d.ctxWindow !== undefined) {
				ctx += ` ${seg(C.dim, `${formatTokens(d.ctxUsed)}/${formatTokens(d.ctxWindow)}`)}`;
			}
		}
		const groups = [ctx];
		if (withSys) {
			const num = (v: number | undefined, warn: number, crit: number): string =>
				v === undefined ? seg(C.dim, "–%") : seg(levelColor(v, warn, crit), `${Math.round(v)}%`);
			groups.push(
				`${seg(C.dim, "CPU")} ${num(d.cpu, 70, 90)} ${seg(C.dim, "MEM")} ${num(d.mem, 80, 92)}`,
			);
		}
		let roles = d.rolesEnabled
			? `${seg(C.dim, "roles")} ${seg(C.green, "● auto")}`
			: `${seg(C.dim, "roles ○ off")}`;
		if (withMcp) {
			roles += `${DOT}${seg(C.teal, `MCP ${d.mcpCount === undefined ? "–" : d.mcpCount}`)}`;
		}
		groups.push(roles);
		return groups.join(SEP);
	};

	const attempts: Array<[number, boolean, boolean]> = [
		[10, true, true],
		[10, false, true],
		[10, false, false],
		[5, false, false],
	];
	for (const [cells, sys, mcp] of attempts) {
		const line = build(cells, sys, mcp);
		if (visibleLength(line) <= width) return line;
	}
	return build(5, false, false);
}
