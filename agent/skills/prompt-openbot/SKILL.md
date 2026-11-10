---
name: prompt-openbot
description: "Turns a rough request, or an existing prompt-forge result, into a ready-to-run task for an OpenBot agent-kit bot. Writes the prompt, picks the right bot from the kit's roster (cloud-finops, sre, qa-engineer, data-engineer and the rest), saves the prompt to a file, and prints the exact command that runs the bot in Claude Code (claude -p with openbot:<id>) and in OpenBot Desktop (openbot-cli run). Use when the user wants an openbot agent to do something, says 'suruh agent', 'jalankan pakai agent', 'bikin prompt untuk openbot agent', 'give me the command to run this on the agent', 'which agent should run this', or pastes a prompt and asks who should run it, even if they never say prompt-openbot."
license: MIT
---

# prompt-openbot

Takes a request and produces three things: a self-contained English prompt, the name of the one OpenBot agent-kit bot that should run it, and copy-paste commands that run that bot in Claude Code and in OpenBot Desktop. The prompt itself is built the way prompt-forge builds prompts; this skill adds the routing, the agent-specific rules, the saved file and the commands.

## Local values

Change a value here if it moves. Expand `~` to the full home path in every path you write or print, so the commands work from any directory.

| Name | Value | Meaning |
|---|---|---|
| `KIT_DIR` | `~/Artifacts/labs/src/openbot-agent-kit` | The openbot-agent-kit checkout; its `bots/*.yaml` is the roster |
| `PROMPT_FORGE_FILE` | `../prompt-forge/SKILL.md` (relative to this skill's directory) | The skill whose procedure builds the prompt |
| `OUTPUT_DIR` | `~/Artifacts/labs/tmp/prompt-openbot` | Where saved prompt files go |
| `OPENBOT_CLI` | `node /Applications/OpenBot.app/Contents/Resources/cli/openbot-cli.mjs` | Command that starts the OpenBot Desktop CLI |
| `CLAUDE_CMD` | `claude-profile edith-default` | Command that starts Claude Code; plain `claude` when the wrapper is not installed |

## Rules

- **Read the roster on every run.** Bots are added and changed; a remembered list goes stale and sends work to an agent that no longer fits. If `KIT_DIR/bots` is missing, say so, give the prompt, and stop without a command.
- **One bot by default.** In Claude Code an agent cannot hand work to another agent, so every extra bot means the user passes output along by hand. Chain only when the request clearly needs different roles in sequence.
- **Never route work to a bot whose guardrails forbid it.** Each bot has guardrails, `readOnly` and `denyCommands`; a prompt that asks for a forbidden action wastes a run, and the bot will refuse or be blocked by the guard hook. Check before you hand over.
- **The prompt must stand alone.** The bot does not see this conversation. Anything it needs (paths, data, constraints, the previous bot's output) goes in the prompt or in a file the prompt names.
- **Never put a secret value in the prompt, the file or a command.** Name the environment variable instead. The saved file and shell history outlive the session.
- **Do not run the command unless the user asks.** It starts a real agent that can take many minutes, spend money and touch files.
- **Do not invent facts, names or numbers.** Use a placeholder, as prompt-forge does.

## Steps

1. **Classify the input.**
   - A finished prompt (it has headings such as Task, Context, Requirements, or the user says it came from prompt-forge): keep it verbatim, in its original wording. Do not rewrite or translate it. Go to step 2.
   - A rough request: read `PROMPT_FORGE_FILE` in full and follow its steps 1 to 5 to build the prompt. If its blocking-gap check says to ask questions, ask them and stop. No agent, no command, until the request is clear.
2. **Read the roster.** For each file in `KIT_DIR/bots`, read `id`, `name`, `title`, `readOnly`, `persona`, `guardrails` and `denyCommands`. Skip the skills list.
3. **Choose.** Read `references/routing.md`, then pick the bot whose persona covers the prompt's main deliverable. Decide one of: one bot, a chain, or none. If routing.md names an id that is not in the roster, trust the roster.
   - Choose none when the central action is forbidden to every fitting bot (tagging, publishing, merging, deploying, applying infrastructure, restarting workloads), or when the work needs a live back-and-forth with the user. Say who does it instead (the user, or the main session) and still offer the preparatory part to the nearest bot.
4. **Check the fit.** Compare what the prompt requires (commits, pushes, tags, applies, deletes, file writes) with the chosen bot's guardrails, `denyCommands` and `readOnly`. If the prompt asks for something forbidden, remove that action from the prompt, say so in the notes, and keep the rest. Never reword a guardrail to get around it.
5. **Add the agent rules.** Append this block to the prompt. Drop the readOnly bullet for bots that may write files:

   ```
   ## Agent rules
   - Work from this brief alone. Where information is missing, state an assumption in your result and continue, unless one of your guardrails tells you to stop and ask.
   - Do not commit, push or merge, and change nothing outside the files this task names.
   - Do not create or change files; give your result in your reply.   (readOnly bots only)
   - Finish with what you did, the files you wrote with their paths, the commands you ran with their output, and open questions.
   ```
6. **Save the prompt.** Create `OUTPUT_DIR` if needed and write the prompt, exactly as it will be sent and with no code fence, to `OUTPUT_DIR/<YYYY-MM-DD>-<slug>.md`. The slug is up to five lowercase words from the task. If the name exists, add `-2`.
7. **Build the commands.** Read `references/commands.md` and fill in the bot id, the bot name, the file path and the permission flags. Derive the flags from what the prompt requires, using the table there; never grant a bare `Bash` or `Write` the task does not need.
8. **Answer** with the output template below.

## Output

Notes use the language the user wrote in. The prompt and the commands are English.

````
**Agent:** <name> (`openbot:<id>` in Claude Code, "<name>" in OpenBot Desktop). <One line: why this bot. Name a close alternative only if one exists.>

```
<the prompt, including the Agent rules block>
```

**Saved:** `<path>`

**Run in Claude Code**
```sh
<command>
```

**Run in OpenBot Desktop**
```sh
<command>
```

**Notes**
- <Assumptions you made>
- <Placeholders to fill in the saved file before running>
- <Actions you removed from the prompt because the bot may not do them, and who does them instead>
- <Permission flags you added and why>
````

Use a four-backtick fence for the prompt when it contains a fenced block. Omit a Notes bullet that has nothing to say. When placeholders remain, say so right above the commands: the file must be edited before it runs.

For a chain, print one prompt and one command pair per stage, and the glue between stages from `references/commands.md`. For "none", print the prompt (if one was built) and the reason, with no commands.

## Reference files

- `references/routing.md`: which bot fits which kind of work, and which actions no bot may take. Read at step 3.
- `references/commands.md`: command templates for Claude Code and OpenBot Desktop, permission flags, exit codes and chaining. Read at step 7.
- `references/examples.md`: worked examples (a pasted prompt, a rough request that needs a chain, a request no bot may do). Read when unsure about the shape of the answer.
