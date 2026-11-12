/**
 * Herdr desktop status reporter
 *
 * Reports pi's state (idle / working / blocked) to the Herdr desktop app's
 * sidebar through the OSC 7501 terminal escape, which the desktop core reads
 * from the program's stdout:
 *
 *   ESC ] 7501 ; state=<state>:app=pi[:kind=..][:progress=..][:title=<b64>][:msg=<b64>] ESC \
 *
 * Herdr's managed integration (herdr-agent-state.ts) only covers the herdr TUI
 * (HERDR_ENV=1), so inside the desktop app `hc get <terminal>` shows
 * `reported: false` without this extension.
 *
 * Enabled only in the Herdr desktop app (HC_TERMINAL_SOCKET set), outside the
 * herdr TUI (HERDR_ENV !== "1", so nothing is reported twice) and in the
 * interactive TUI (ctx.mode === "tui"). Everywhere else it does nothing.
 *
 * msg is always a fixed label ("Working", "Idle", "Needs input"); prompt text,
 * tool names, paths and model output are never sent.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export type HcState = "idle" | "working" | "done" | "blocked" | "error";
export type HcKind = "permission" | "question" | "auth";

export interface HcStatus {
	state: HcState;
	msg?: string;
	kind?: HcKind;
	progress?: number;
	title?: string;
}

const MAX_TITLE = 192;
const MAX_MSG = 2048;

const b64 = (text: string, max: number): string => Buffer.from(text.slice(0, max), "utf8").toString("base64");

/**
 * Build the full OSC 7501 sequence (pure, no side effects).
 */
export const buildStatus = ({ state, msg, kind, progress, title }: HcStatus): string => {
	const fields = [`state=${state}`, "app=pi"];
	if (kind && state === "blocked") fields.push(`kind=${kind}`);
	if (typeof progress === "number" && Number.isFinite(progress) && (state === "working" || state === "blocked")) {
		fields.push(`progress=${Math.min(100, Math.max(0, Math.round(progress)))}`);
	}
	if (title) fields.push(`title=${b64(title, MAX_TITLE)}`);
	if (msg) fields.push(`msg=${b64(msg, MAX_MSG)}`);
	return `\x1b]7501;${fields.join(":")}\x1b\\`;
};

export const CLEAR = "\x1b]7501;state=clear:app=pi\x1b\\";

const enabled = (): boolean => Boolean(process.env.HC_TERMINAL_SOCKET) && process.env.HERDR_ENV !== "1";

export default function (pi: ExtensionAPI) {
	if (!enabled()) return;

	let rootSession = false;
	let agentActive = false;
	let blockedCount = 0;
	let last: string | undefined;

	const emit = (sequence: string): void => {
		if (sequence === last) return;
		last = sequence;
		try {
			process.stdout.write(sequence);
		} catch {
			// Never throw into pi.
		}
	};

	const publish = (): void => {
		if (blockedCount > 0) {
			emit(buildStatus({ state: "blocked", kind: "question", msg: "Needs input" }));
		} else if (agentActive) {
			emit(buildStatus({ state: "working", msg: "Working" }));
		} else {
			emit(buildStatus({ state: "idle", msg: "Idle" }));
		}
	};

	// Herdr's convention for "waiting on a person": an extension that opens a
	// dialog emits herdr:blocked {active, label} (herdr-agent-state.ts listens to
	// the same event). pi has no generic dialog hook and nothing emits it in this
	// setup today, so `blocked` is never reported yet; any extension that follows
	// the convention will light it up without changes here.
	pi.events.on("herdr:blocked", (data: { active?: boolean } | undefined) => {
		if (!rootSession) return;
		blockedCount = data?.active ? blockedCount + 1 : Math.max(0, blockedCount - 1);
		publish();
	});

	pi.on("session_start", async (_event, ctx) => {
		if (ctx?.mode !== "tui") return;
		rootSession = true;
		last = undefined;
		blockedCount = 0;
		// A reload can replace this extension mid-run without another agent_start.
		agentActive = ctx?.isIdle?.() === false;
		publish();
	});

	pi.on("agent_start", () => {
		if (!rootSession) return;
		agentActive = true;
		publish();
	});

	pi.on("agent_settled", (_event, ctx) => {
		if (!rootSession || ctx?.isIdle?.() !== true) return;
		agentActive = false;
		publish();
	});

	pi.on("session_shutdown", () => {
		if (!rootSession) return;
		rootSession = false;
		agentActive = false;
		blockedCount = 0;
		emit(CLEAR);
	});
}
