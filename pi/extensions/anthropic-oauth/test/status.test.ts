import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { AnthropicAuthConfig } from "../src/config.ts";
import { describeCredential, formatStatus, type StatusRegistry } from "../src/status.ts";

interface FakeProvider {
	auth: { configured: boolean; source?: "stored" | "environment"; label?: string };
	authType?: "oauth" | "api_key";
	hasModels: boolean;
}

function fakeRegistry(providers: Record<string, FakeProvider>): StatusRegistry {
	return {
		getProvider: (id: string) => (providers[id] ? { id } : undefined),
		getProviderAuthStatus: (id: string) => providers[id]?.auth ?? { configured: false },
		getAll: () =>
			Object.entries(providers)
				.filter(([, p]) => p.hasModels)
				.map(([id]) => ({ id: `${id}-model`, provider: id })),
		isUsingOAuth: (model: { provider: string }) => providers[model.provider]?.authType === "oauth",
	} as unknown as StatusRegistry;
}

const registry = fakeRegistry({
	empty: { auth: { configured: false }, hasModels: true },
	modelless: { auth: { configured: true, source: "stored" }, authType: "oauth", hasModels: false },
	anthropic: { auth: { configured: true, source: "stored" }, authType: "oauth", hasModels: true },
	keyed: { auth: { configured: true, source: "environment", label: "ANTHROPIC_API_KEY" }, authType: "api_key", hasModels: true },
});

describe("describeCredential", () => {
	it("classifies each registry state", () => {
		assert.deepEqual(describeCredential(registry, "missing"), { kind: "unregistered" });
		assert.deepEqual(describeCredential(registry, "empty"), { kind: "none" });
		assert.deepEqual(describeCredential(registry, "modelless"), { kind: "no-models", source: "stored", label: undefined });
		assert.deepEqual(describeCredential(registry, "anthropic"), { kind: "oauth", source: "stored", label: undefined });
		assert.deepEqual(describeCredential(registry, "keyed"), {
			kind: "non-oauth",
			source: "environment",
			label: "ANTHROPIC_API_KEY",
		});
	});
});

describe("formatStatus", () => {
	const config: AnthropicAuthConfig = { path: "/agent/extensions/pi-anthropic-auth/config.json", found: true, providers: [], warnings: [] };
	const providers = [
		{ name: "anthropic", credential: { kind: "oauth", source: "stored" } },
		{ name: "keyed", credential: { kind: "non-oauth", source: "environment", label: "ANTHROPIC_API_KEY" } },
		{ name: "modelless", credential: { kind: "no-models" } },
		{ name: "empty", credential: { kind: "none" } },
		{ name: "missing", credential: { kind: "unregistered" } },
	] as const;

	it("renders the full report with one line per provider", () => {
		const text = formatStatus({ version: "0.1.0", modulePath: "/pkg/src/index.ts", config, providers: [...providers] });
		assert.equal(
			text,
			[
				"pi-anthropic-auth v0.1.0",
				"  module:   /pkg/src/index.ts",
				"  requests: unmodified (no request hooks or provider overrides registered)",
				"  config:   /agent/extensions/pi-anthropic-auth/config.json (loaded)",
				"  providers:",
				"    anthropic: OAuth (stored)",
				"    keyed: API key or other non-OAuth credential (environment: ANTHROPIC_API_KEY)",
				"    modelless: credentials configured (unknown source), type unknown: provider has no models",
				"    empty: no credentials",
				"    missing: not registered with Pi",
				"  warnings: none",
			].join("\n"),
		);
	});

	it("lists warnings and reports a missing config", () => {
		const text = formatStatus({
			version: "0.1.0",
			modulePath: "/pkg/src/index.ts",
			config: { ...config, found: false, warnings: ["first", "second"] },
			providers: [],
		});
		assert.ok(text.includes("config.json (not found)"));
		assert.ok(text.endsWith("  warnings:\n    first\n    second"));
	});
});
