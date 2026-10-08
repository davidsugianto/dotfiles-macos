import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, describe, it } from "node:test";
import { configPath, loadConfig, parseConfig } from "../src/config.ts";

const dirs: string[] = [];
after(() => {
	for (const dir of dirs) rmSync(dir, { recursive: true, force: true });
});

function agentDirWith(content?: string): string {
	const dir = mkdtempSync(join(tmpdir(), "pi-anthropic-auth-"));
	dirs.push(dir);
	if (content !== undefined) {
		mkdirSync(join(dir, "extensions", "pi-anthropic-auth"), { recursive: true });
		writeFileSync(configPath(dir), content);
	}
	return dir;
}

describe("loadConfig", () => {
	it("falls back to anthropic without warnings when the file is missing", () => {
		const config = loadConfig(agentDirWith());
		assert.equal(config.found, false);
		assert.deepEqual(config.providers, ["anthropic"]);
		assert.deepEqual(config.warnings, []);
	});

	it("appends configured providers from the global config path", () => {
		const dir = agentDirWith(JSON.stringify({ providers: ["anthropic-2", "anthropic-3"] }));
		const config = loadConfig(dir);
		assert.equal(config.path, join(dir, "extensions", "pi-anthropic-auth", "config.json"));
		assert.equal(config.found, true);
		assert.deepEqual(config.providers, ["anthropic", "anthropic-2", "anthropic-3"]);
		assert.deepEqual(config.warnings, []);
	});

	it("warns when the path cannot be read as a file", () => {
		const dir = agentDirWith();
		mkdirSync(configPath(dir), { recursive: true });
		const config = loadConfig(dir);
		assert.equal(config.found, false);
		assert.deepEqual(config.providers, ["anthropic"]);
		assert.equal(config.warnings.length, 1);
		assert.match(config.warnings[0]!, /^cannot read file: /);
	});
});

describe("parseConfig", () => {
	it("trims and dedupes entries, dropping anthropic silently", () => {
		const result = parseConfig(JSON.stringify({ providers: [" anthropic-2 ", "anthropic", "anthropic-2", "anthropic-3"] }));
		assert.deepEqual(result, { providers: ["anthropic", "anthropic-2", "anthropic-3"], warnings: [] });
	});

	it("accepts an object without providers", () => {
		assert.deepEqual(parseConfig("{}"), { providers: ["anthropic"], warnings: [] });
	});

	it("reports invalid JSON", () => {
		const result = parseConfig("{not json");
		assert.deepEqual(result.providers, ["anthropic"]);
		assert.equal(result.warnings.length, 1);
		assert.match(result.warnings[0]!, /^invalid JSON: /);
	});

	it("rejects a non-object top level", () => {
		for (const text of ["[]", "null", "42"]) {
			assert.deepEqual(parseConfig(text), { providers: ["anthropic"], warnings: ["expected a JSON object at top level"] });
		}
	});

	it("rejects non-array providers", () => {
		assert.deepEqual(parseConfig(JSON.stringify({ providers: "x" })), {
			providers: ["anthropic"],
			warnings: ['"providers" must be an array of strings'],
		});
	});

	it("keeps valid entries and names invalid ones by original index", () => {
		assert.deepEqual(parseConfig(JSON.stringify({ providers: ["a", 1, ""] })), {
			providers: ["anthropic", "a"],
			warnings: ["providers[1] must be a non-empty string", "providers[2] must be a non-empty string"],
		});
	});

	it("warns on unknown keys and keeps valid providers", () => {
		assert.deepEqual(parseConfig(JSON.stringify({ providers: ["anthropic-2"], extra: true })), {
			providers: ["anthropic", "anthropic-2"],
			warnings: ['unknown key "extra" ignored'],
		});
	});
});
