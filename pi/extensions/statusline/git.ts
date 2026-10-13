/**
 * Git state for the footer: branch, dirty count, ahead/behind.
 * Only node imports, so tests can load it with bun/node (no pi runtime needed).
 */

import { execFileSync } from "node:child_process";

export interface GitInfo {
	branch?: string;
	dirty: number;
	ahead: number;
	behind: number;
	at: number;
}

// Read-only on purpose: GIT_OPTIONAL_LOCKS=0 stops `git status` from refreshing and
// rewriting the index (and holding index.lock) under the agent's own git commands, and
// core.fsmonitor=false keeps an untrusted checkout's fsmonitor command from running.
function git(cwd: string, args: string[]): string | undefined {
	try {
		return execFileSync("git", ["-c", "core.fsmonitor=false", ...args], {
			cwd,
			encoding: "utf8",
			timeout: 2_000,
			stdio: ["ignore", "pipe", "ignore"],
			env: { ...process.env, GIT_OPTIONAL_LOCKS: "0" },
		});
	} catch {
		return undefined;
	}
}

export function readGit(cwd: string): GitInfo {
	const info: GitInfo = { dirty: 0, ahead: 0, behind: 0, at: Date.now() };
	const branch = git(cwd, ["rev-parse", "--abbrev-ref", "HEAD"])?.trim();
	if (!branch) return info;
	info.branch = branch === "HEAD" ? (git(cwd, ["rev-parse", "--short", "HEAD"])?.trim() ?? "HEAD") : branch;
	const status = git(cwd, ["status", "--porcelain"]);
	info.dirty = status ? status.split("\n").filter((l) => l.length > 0).length : 0;
	const lr = git(cwd, ["rev-list", "--left-right", "--count", "@{u}...HEAD"])?.trim() ?? "0 0";
	const [behind, ahead] = lr.split(/\s+/).map((n) => Number.parseInt(n, 10) || 0);
	info.behind = behind ?? 0;
	info.ahead = ahead ?? 0;
	return info;
}
