import { promises as fs } from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HANDOFF_DIR = path.join(os.homedir(), ".pi", "agent", "handoffs");
const ARCHIVE_DIR = path.join(HANDOFF_DIR, "_archived");
const DONE_STATUSES = new Set(["done", "complete", "completed", "archived"]);

type Handoff = {
	file: string;
	name: string;
	title: string;
	status: string;
};

function today(): string {
	const date = new Date();
	return [date.getFullYear(), date.getMonth() + 1, date.getDate()]
		.map((part, index) => index === 0 ? String(part) : String(part).padStart(2, "0"))
		.join("-");
}

function slugify(title: string): string {
	return title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 80) || "task";
}

function frontmatter(content: string): string {
	return content.match(/^---\s*\n([\s\S]*?)\n---\s*(?:\n|$)/)?.[1] ?? "";
}

function field(content: string, name: string): string | undefined {
	const value = frontmatter(content).match(new RegExp(`^${name}\\s*:\\s*["']?([^"'\\n]+?)["']?\\s*$`, "mi"))?.[1];
	return value?.trim();
}

function handoffStatus(content: string): string {
	return field(content, "status")?.toLowerCase().replace(/[_-]/g, " ").split("#", 1)[0].trim() ?? "active";
}

function handoffTitle(content: string, name: string): string {
	return field(content, "title") ?? content.match(/^#\s+(.+)$/m)?.[1]?.trim() ?? name.replace(/\.md$/, "");
}

async function readHandoffs(): Promise<Handoff[]> {
	await fs.mkdir(HANDOFF_DIR, { recursive: true });
	const entries = await fs.readdir(HANDOFF_DIR, { withFileTypes: true });
	const files = entries.filter((entry) => entry.isFile() && entry.name.endsWith(".md"));
	const handoffs: Handoff[] = [];

	for (const entry of files) {
		const file = path.join(HANDOFF_DIR, entry.name);
		const content = await fs.readFile(file, "utf8");
		handoffs.push({
			file,
			name: entry.name,
			title: handoffTitle(content, entry.name),
			status: handoffStatus(content),
		});
	}

	return handoffs;
}

async function archiveDone(handoff: Handoff, notify: (message: string, type?: "info" | "warning" | "error") => void): Promise<boolean> {
	if (!DONE_STATUSES.has(handoff.status)) return false;
	await fs.mkdir(ARCHIVE_DIR, { recursive: true });
	const target = path.join(ARCHIVE_DIR, handoff.name);

	try {
		await fs.stat(target);
		notify(`Handoff archive already exists: ${handoff.name}`, "warning");
		return false;
	} catch {
		// Target does not exist.
	}

	await fs.rename(handoff.file, target);
	return true;
}

async function listActive(notify: (message: string, type?: "info" | "warning" | "error") => void): Promise<void> {
	const handoffs = await readHandoffs();
	for (const handoff of handoffs) {
		try {
			await archiveDone(handoff, notify);
		} catch (error) {
			notify(`Could not archive ${handoff.name}: ${error instanceof Error ? error.message : String(error)}`, "error");
		}
	}

	const active = handoffs.filter((handoff) => !DONE_STATUSES.has(handoff.status));
	if (active.length === 0) {
		notify("No active handoff tasks.", "info");
		return;
	}

	notify([
		"Active handoff tasks:",
		...active.map((handoff) => `- ${handoff.title} [${handoff.status}] — ${handoff.name}`),
	].join("\n"), "info");
}

async function createHandoff(title: string, notify: (message: string, type?: "info" | "warning" | "error") => void): Promise<void> {
	const cleanTitle = title.replace(/\s+/g, " ").trim();
	await fs.mkdir(HANDOFF_DIR, { recursive: true });
	const name = `${today()}-handoff-${slugify(cleanTitle)}.md`;
	const file = path.join(HANDOFF_DIR, name);
	const content = `---
title: ${cleanTitle}
status: active
created: ${today()}
---

# Handoff: ${cleanTitle}

## Context

## Done

## Remaining

## Next step

## Files

## Validation
`;

	try {
		await fs.writeFile(file, content, { encoding: "utf8", flag: "wx" });
		notify(`Created handoff: ${name}`, "info");
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "EEXIST") {
			notify(`Handoff already exists: ${name}`, "warning");
			return;
		}
		throw error;
	}
}

export default function manageHandoff(pi: ExtensionAPI) {
	pi.registerCommand("handoff", {
		description: "List active handoffs, archive completed ones, or create /handoff <title>",
		handler: async (args, ctx) => {
			const notify = (message: string, type?: "info" | "warning" | "error") => ctx.ui.notify(message, type);
			try {
				const title = args.trim();
				if (title && title !== "list") await createHandoff(title, notify);
				else await listActive(notify);
			} catch (error) {
				ctx.ui.notify(`/handoff failed: ${error instanceof Error ? error.message : String(error)}`, "error");
			}
		},
	});

	pi.registerCommand("manage-handoff", {
		description: "Run handoff templates: /manage-handoff do <title> or work <filename>",
		handler: async (args, ctx) => {
			const notify = (message: string, type?: "info" | "warning" | "error") => ctx.ui.notify(message, type);
			const input = args.trim();
			const [action, ...rest] = input.split(/\s+/);
			const value = rest.join(" ").trim();

			if (!action || action === "list") {
				await listActive(notify);
				return;
			}
			if (action === "create" && value) {
				await createHandoff(value, notify);
				return;
			}
			if (action === "do") {
				pi.sendUserMessage(value ? `/do-handoff ${value}` : "/do-handoff", { expandPromptTemplates: true });
				return;
			}
			if (action === "work" && value) {
				pi.sendUserMessage(`/work-on-handoff ${value}`, { expandPromptTemplates: true });
				return;
			}

			ctx.ui.notify("Usage: /manage-handoff [list|create <title>|do [title]|work <filename>]", "warning");
		},
	});
}
