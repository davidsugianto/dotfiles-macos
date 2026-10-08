import { readFileSync } from "node:fs";
import { join } from "node:path";

export const DEFAULT_PROVIDER = "anthropic";

export interface AnthropicAuthConfig {
	path: string;
	found: boolean;
	providers: string[];
	warnings: string[];
}

export function configPath(agentDir: string): string {
	return join(agentDir, "extensions", "pi-anthropic-auth", "config.json");
}

export function parseConfig(text: string): { providers: string[]; warnings: string[] } {
	const providers = [DEFAULT_PROVIDER];
	const warnings: string[] = [];

	let data: unknown;
	try {
		data = JSON.parse(text);
	} catch (err) {
		warnings.push(`invalid JSON: ${(err as Error).message}`);
		return { providers, warnings };
	}

	if (typeof data !== "object" || data === null || Array.isArray(data)) {
		warnings.push("expected a JSON object at top level");
		return { providers, warnings };
	}

	for (const [key, value] of Object.entries(data)) {
		if (key !== "providers") {
			warnings.push(`unknown key "${key}" ignored`);
			continue;
		}
		if (!Array.isArray(value)) {
			warnings.push(`"providers" must be an array of strings`);
			continue;
		}
		value.forEach((entry: unknown, i) => {
			const name = typeof entry === "string" ? entry.trim() : "";
			if (name === "") {
				warnings.push(`providers[${i}] must be a non-empty string`);
				return;
			}
			if (!providers.includes(name)) providers.push(name);
		});
	}

	return { providers, warnings };
}

export function loadConfig(agentDir: string): AnthropicAuthConfig {
	const path = configPath(agentDir);
	let text: string;
	try {
		text = readFileSync(path, "utf8");
	} catch (err) {
		const error = err as NodeJS.ErrnoException;
		const warnings = error.code === "ENOENT" ? [] : [`cannot read file: ${error.message}`];
		return { path, found: false, providers: [DEFAULT_PROVIDER], warnings };
	}
	return { path, found: true, ...parseConfig(text) };
}
