import type { ModelRegistry } from "@earendil-works/pi-coding-agent";
import type { AnthropicAuthConfig } from "./config.ts";

export type StatusRegistry = Pick<ModelRegistry, "getProvider" | "getProviderAuthStatus" | "getAll" | "isUsingOAuth">;

export type ProviderCredential =
	| { kind: "unregistered" }
	| { kind: "none" }
	| { kind: "no-models"; source?: string; label?: string }
	| { kind: "oauth" | "non-oauth"; source?: string; label?: string };

/**
 * Classify a provider's credential from the registry's synchronous snapshot.
 * Never resolves or refreshes secrets (no getApiKeyAndHeaders/getApiKeyForProvider/getProviderAuth).
 */
export function describeCredential(registry: StatusRegistry, provider: string): ProviderCredential {
	if (registry.getProvider(provider) === undefined) return { kind: "unregistered" };
	const { configured, source, label } = registry.getProviderAuthStatus(provider);
	if (!configured) return { kind: "none" };
	const model = registry.getAll().find((m) => m.provider === provider);
	if (model === undefined) return { kind: "no-models", source, label };
	return { kind: registry.isUsingOAuth(model) ? "oauth" : "non-oauth", source, label };
}

export interface StatusReport {
	version: string;
	modulePath: string;
	config: AnthropicAuthConfig;
	providers: { name: string; credential: ProviderCredential }[];
}

function describeProvider(credential: ProviderCredential): string {
	if (credential.kind === "unregistered") return "not registered with Pi";
	if (credential.kind === "none") return "no credentials";
	const src = credential.source === undefined ? "unknown source" : credential.label === undefined ? credential.source : `${credential.source}: ${credential.label}`;
	switch (credential.kind) {
		case "oauth":
			return `OAuth (${src})`;
		case "non-oauth":
			return `API key or other non-OAuth credential (${src})`;
		case "no-models":
			return `credentials configured (${src}), type unknown: provider has no models`;
	}
}

export function formatStatus(report: StatusReport): string {
	const { config } = report;
	const lines = [
		`pi-anthropic-auth v${report.version}`,
		`  module:   ${report.modulePath}`,
		"  requests: unmodified (no request hooks or provider overrides registered)",
		`  config:   ${config.path} (${config.found ? "loaded" : "not found"})`,
		"  providers:",
		...report.providers.map(({ name, credential }) => `    ${name}: ${describeProvider(credential)}`),
	];
	if (config.warnings.length === 0) lines.push("  warnings: none");
	else lines.push("  warnings:", ...config.warnings.map((w) => `    ${w}`));
	return lines.join("\n");
}
