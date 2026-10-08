import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, describe, it } from "node:test";
import type { ExtensionAPI, ExtensionCommandContext, RegisteredCommand } from "@earendil-works/pi-coding-agent";
import { configPath } from "../src/config.ts";
import { registerAnthropicAuth, STATUS_COMMAND } from "../src/extension.ts";

type CommandOptions = Omit<RegisteredCommand, "name" | "sourceInfo">;

const dirs: string[] = [];
after(() => {
	for (const dir of dirs) rmSync(dir, { recursive: true, force: true });
});

function register(agentDir: string): Map<string, CommandOptions> {
	const commands = new Map<string, CommandOptions>();
	const pi = {
		registerCommand: (name: string, options: CommandOptions) => commands.set(name, options),
		on: () => {
			throw new Error("extension must not register event hooks");
		},
		registerProvider: () => {
			throw new Error("extension must not register provider overrides");
		},
	} as unknown as ExtensionAPI;
	registerAnthropicAuth(pi, { agentDir, version: "0.1.0", modulePath: "/pkg/src/index.ts" });
	return commands;
}

async function runStatus(agentDir: string): Promise<{ message: string; level: string | undefined }> {
	const notes: { message: string; level: string | undefined }[] = [];
	const ctx = {
		modelRegistry: {
			getProvider: () => undefined,
			getProviderAuthStatus: () => ({ configured: false }),
			getAll: () => [],
			isUsingOAuth: () => false,
		},
		ui: { notify: (message: string, level?: string) => notes.push({ message, level }) },
	} as unknown as ExtensionCommandContext;
	await register(agentDir).get(STATUS_COMMAND)!.handler("ignored args", ctx);
	assert.equal(notes.length, 1);
	return notes[0]!;
}

function tempAgentDir(): string {
	const dir = mkdtempSync(join(tmpdir(), "pi-anthropic-auth-"));
	dirs.push(dir);
	return dir;
}

describe("registerAnthropicAuth", () => {
	it("registers only the status command", () => {
		assert.deepEqual([...register(tempAgentDir()).keys()], ["anthropic-auth:status"]);
	});

	it("notifies with a warning level when the config is malformed", async () => {
		const dir = tempAgentDir();
		mkdirSync(join(dir, "extensions", "pi-anthropic-auth"), { recursive: true });
		writeFileSync(configPath(dir), JSON.stringify({ providers: ["anthropic-2", 42], extra: true }));
		const { message, level } = await runStatus(dir);
		assert.equal(level, "warning");
		assert.ok(message.includes("    anthropic-2: not registered with Pi"));
		assert.ok(message.includes("    providers[1] must be a non-empty string"));
		assert.ok(message.includes('    unknown key "extra" ignored'));
	});

	it("notifies with an info level when no config exists", async () => {
		const { message, level } = await runStatus(tempAgentDir());
		assert.equal(level, "info");
		assert.ok(message.includes("    anthropic: not registered with Pi"));
		assert.ok(message.endsWith("  warnings: none"));
	});
});
