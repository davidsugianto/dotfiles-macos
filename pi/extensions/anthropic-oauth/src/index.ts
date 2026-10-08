import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { type ExtensionAPI, getAgentDir } from "@earendil-works/pi-coding-agent";
import { registerAnthropicAuth } from "./extension.ts";

export default function piAnthropicAuth(pi: ExtensionAPI): void {
	const { version } = JSON.parse(readFileSync(new URL("../package.json", import.meta.url), "utf8")) as { version: string };
	registerAnthropicAuth(pi, { agentDir: getAgentDir(), version, modulePath: fileURLToPath(import.meta.url) });
}
