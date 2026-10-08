import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { loadConfig } from "./config.ts";
import { describeCredential, formatStatus } from "./status.ts";

export const STATUS_COMMAND = "anthropic-auth:status";

export interface AnthropicAuthOptions {
	agentDir: string;
	version: string;
	modulePath: string;
}

/** Registers only the status command: no event hooks, no provider overrides. */
export function registerAnthropicAuth(pi: ExtensionAPI, options: AnthropicAuthOptions): void {
	pi.registerCommand(STATUS_COMMAND, {
		description: "Show pi-anthropic-auth status: Anthropic providers, credential types, config warnings",
		handler: async (_args, ctx) => {
			const config = loadConfig(options.agentDir);
			const providers = config.providers.map((name) => ({
				name,
				credential: describeCredential(ctx.modelRegistry, name),
			}));
			const report = formatStatus({ version: options.version, modulePath: options.modulePath, config, providers });
			ctx.ui.notify(report, config.warnings.length > 0 ? "warning" : "info");
		},
	});
}
