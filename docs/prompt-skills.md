# Prompt skills: prompt-forge and prompt-openbot

Two skills that turn rough text into a prompt, and a prompt into a command that runs an agent. Back to the [README](../README.md). For how to invoke skills in general, see [example-skills-cmd.md](example-skills-cmd.md).

| Skill | Input | Output |
|---|---|---|
| `prompt-forge` | Rough Indonesian, mixed or messy English text | One clean English prompt, plus notes (assumptions, placeholders) |
| `prompt-openbot` | A rough request, or a finished prompt-forge result | The prompt, the right [openbot-agent-kit](https://github.com/davidsugianto/openbot-agent-kit) bot for it, a saved prompt file, and ready-to-run commands for Claude Code and OpenBot Desktop |

`prompt-openbot` builds on `prompt-forge`: for a rough request it follows prompt-forge's procedure, then adds the routing, the agent rules and the commands. For a prompt you already have, it keeps the prompt as written.

## Where they live

Both are single-file skills in `agent/skills/`, shared by Claude Code, pi and omp:

```
agent/skills/prompt-forge/      SKILL.md, references/examples.md
agent/skills/prompt-openbot/    SKILL.md, references/{routing,commands,examples}.md
```

`setup.sh` links each folder into `~/.agents/skills/` (read by pi and omp) and, from there, into `~/.claude/skills/`. To link one by hand:

```sh
ln -sfn "$PWD/agent/skills/prompt-openbot" ~/.agents/skills/prompt-openbot
ln -sfn ~/.agents/skills/prompt-openbot ~/.claude/skills/prompt-openbot
```

Start a new session afterwards; open sessions do not pick up new skills. Keep the two skill folders side by side: `prompt-openbot` reads `../prompt-forge/SKILL.md`.

## Use prompt-forge

Ask for a prompt from rough text. Claude Code:

```text
/prompt-forge gw mau email ke client bilang deploy delay 2 hari karena ada bug di payment
```

You get one English prompt in a code block, then notes in your language. If the request is too vague (for example "bikin prompt buat analisa data"), it asks up to three questions instead.

## Use prompt-openbot

### Invoke

| Tool | Command |
|---|---|
| Claude Code | `/prompt-openbot <request>` |
| Pi | `/skill:prompt-openbot <request>` |
| Any | Say it in plain words: "suruh agent review test di src/billing", "which agent should run this?" |

Examples:

```text
/prompt-openbot cek flaky test di openbot-agent-kit
```

```text
/prompt-openbot suruh cloud-finops analisa biaya Datadog Product Analytics dan tulis report HTML
```

To route a prompt you already have, paste it:

```text
/prompt-openbot
<paste the prompt-forge result here>
Which agent should run this? Give me the command.
```

### What you get

| Part | Content |
|---|---|
| Agent | The chosen bot and why. A close alternative is named only if there is one. |
| Prompt | The English prompt, ending in an "Agent rules" block |
| Saved | The prompt written to `~/Artifacts/labs/tmp/prompt-openbot/<date>-<slug>.md` |
| Run in Claude Code | `claude-profile ... -p` command with permission flags sized to the task |
| Run in OpenBot Desktop | `openbot-cli run "<Name>" - --wait` command |
| Notes | Assumptions, placeholders to fill, actions removed from the prompt, flags added |

The skill does not run the command. Copy it into a terminal.

### Choosing a bot

The skill reads the roster from `bots/*.yaml` in the openbot-agent-kit checkout on every run, so new bots are picked up without editing the skill. It then:

- picks one bot by the main deliverable (cost analysis goes to `cloud-finops`, test review to `qa-engineer`, an incident to `sre`);
- uses a chain of bots only when each stage needs the previous stage's output;
- removes any action the bot is not allowed to take (committing, tagging, publishing, applying infrastructure) from the prompt and tells you who does it instead;
- prints no command when the central action is forbidden to every bot, and prepares the part a bot can do.

The routing table is `agent/skills/prompt-openbot/references/routing.md`.

### Running the result

- Fill any `[PLACEHOLDER]` in the saved file or the command first.
- Run the Claude Code command from a normal terminal. It starts its own `claude -p` session and prints the agent's final answer to stdout; add `> result.md` to keep it.
- The run is unattended, so tools not listed in `--allowedTools` are denied. The skill adds only what the prompt needs (for example `Bash(curl:*)`, or `Write` with `--permission-mode acceptEdits`). Add more yourself if the agent reports a denied call.
- A reply ending in `(openbot guard, openbot:<id>)` means the prompt asked for something the bot may not do. Change the prompt or do that step yourself.
- For OpenBot Desktop, the app must be running and the bot imported with Local scripts on. Exit code 3 means the bot is waiting for your answer in OpenBot; 5 means OpenBot is unreachable or the bot was not found.

## Change the setup

Machine values sit in the "Local values" table at the top of `agent/skills/prompt-openbot/SKILL.md`:

| Name | Default | Change it when |
|---|---|---|
| `KIT_DIR` | `~/Artifacts/labs/src/openbot-agent-kit` | the kit lives somewhere else |
| `OUTPUT_DIR` | `~/Artifacts/labs/tmp/prompt-openbot` | you want saved prompts elsewhere |
| `OPENBOT_CLI` | `node /Applications/OpenBot.app/Contents/Resources/cli/openbot-cli.mjs` | OpenBot is installed elsewhere |
| `CLAUDE_CMD` | `claude-profile edith-default` | you want another profile, or plain `claude` |

Profile choice matters little here: it sets the model of the session that delegates, while the bot's own model comes from its tier in the kit.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `/prompt-openbot` is not found | start a new session; check `ls ~/.claude/skills/prompt-openbot`; relink with the commands above |
| The skill says the roster is missing | `KIT_DIR` is wrong, or the kit is not cloned; fix the Local values table |
| A new bot is never chosen | check `bots/<id>.yaml` loads (`make check` in the kit); add the bot to `references/routing.md` if it needs a routing hint |
| `claude-profile: command not found` | set `CLAUDE_CMD` to `claude` |
| `openbot:<id>` agent not found when running | install or rebuild the plugin: see the openbot-agent-kit README (`make build-claude`) |
| The agent cannot read or write a path | add `"Read(//<abs path>/**)"` or `"Write"` to `--allowedTools` |
