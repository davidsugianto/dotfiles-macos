# Command templates

`CLAUDE_CMD` and `OPENBOT_CLI` come from the Local values table in SKILL.md; print their values in the commands. Fill `<ID>` (the bot id), `<NAME>` (the bot's `name` field) and `<PROMPT_FILE>` (the saved path). `<DIR>` is the directory the task works in, a `[WORKING_DIR]` placeholder when the prompt does not name one.

## Claude Code

```sh
cd <DIR>
{ echo "Delegate the brief below to the openbot:<ID> agent. Return its final answer unchanged."
  echo
  cat <PROMPT_FILE>
} | <CLAUDE_CMD> -p <PERMISSION_FLAGS>
```

- The prompt goes through stdin. It is multi-line, and `--allowedTools` takes a list that swallows a trailing positional argument.
- The wrapper delegates because the plugin's agents are subagents. The main session's model comes from the profile; the bot's own model comes from its tier.
- `-p` prints the final answer. Append `> <file>` to keep it.
- The run is unattended. A tool call that is not allowed is denied, not prompted, so the flags below decide what the bot can do.

### Permission flags

Derive them from what the prompt requires. Combine rows.

| The task needs | Add |
|---|---|
| Reading files in the current directory | `--allowedTools "Read"` |
| Reading files outside the current directory | `"Read(//<absolute path>/**)"` in the same list |
| Running shell commands | one `"Bash(<command>:*)"` per command the prompt names, for example `"Bash(curl:*)"` and `"Bash(jq:*)"` |
| Creating or editing files | `--permission-mode acceptEdits` and `"Write"` (and `"Edit"` for edits) in the list |

Never add a bare `"Bash"`. Never add `"Write"` or `"Edit"` for a `readOnly` bot; the bot cannot use them. Flags apply to the delegated bot too.

### The guard hook

For every bot, a hook denies `git commit`, `git push`, `git merge` and `gh pr merge`. For `readOnly` bots it also denies shell file writes. Each bot's `denyCommands` are denied as well. A denial reads `(openbot guard, openbot:<ID>)`. It means the brief asked for something the bot may not do: revise the brief, or do that step yourself.

### Other ways to run

- Interactive: start `<CLAUDE_CMD>` and send `Use openbot:<ID> to <task>.`
- The whole session as one bot: `<CLAUDE_CMD> --agent openbot:<ID>`
- Several roles coordinated by the main session: send `Use openbot:team-routing. <task>`

## OpenBot Desktop

```sh
<OPENBOT_CLI> run "<NAME>" - --wait --timeout 30m < <PROMPT_FILE>
```

- `-` reads the task from standard input. `--wait` returns the bot's final answer; without it the command prints a delivery id and returns, and `<OPENBOT_CLI> status "<NAME>" <deliveryId>` checks it later.
- Pick `--timeout` from the work: `10m` for a short answer, `30m` for analysis or a report, `1h` for a build.
- OpenBot must be running, the bot must be imported, and its Local scripts setting must be on. Address the bot by its name or id.
- Append `> <file>` to keep the answer.

| Exit code | Meaning |
|---|---|
| 0 | the bot finished; the answer is printed |
| 1 | the turn failed or OpenBot refused |
| 2 | wrong command line or an empty task |
| 3 | the bot waits for a person: answer in OpenBot, then run `status` |
| 4 | timed out; the work continues in OpenBot |
| 5 | OpenBot cannot be reached, or the bot was not found |

OpenBot has no permission flags and no hook. The bot's guardrails and the "Forbidden shell commands" list in its role file are instructions it follows, not blocks.

## Chaining

Run the stages in order. Save each stage's answer and give it to the next stage after the brief. Stop the chain if a stage fails.

Claude Code:

```sh
set -e
cd <DIR>
{ echo "Delegate the brief below to the openbot:<ID1> agent. Return its final answer unchanged."; echo; cat <PROMPT_FILE_1>; } \
  | <CLAUDE_CMD> -p <FLAGS_1> > <STAGE1_OUT>
{ echo "Delegate the brief below to the openbot:<ID2> agent. Return its final answer unchanged."; echo; cat <PROMPT_FILE_2>; echo; echo "Output of the previous stage:"; cat <STAGE1_OUT>; } \
  | <CLAUDE_CMD> -p <FLAGS_2>
```

OpenBot Desktop:

```sh
set -e
<OPENBOT_CLI> run "<NAME1>" - --wait --timeout 30m < <PROMPT_FILE_1> > <STAGE1_OUT>
{ cat <PROMPT_FILE_2>; echo; echo "Output of the previous stage:"; cat <STAGE1_OUT>; } \
  | <OPENBOT_CLI> run "<NAME2>" - --wait --timeout 30m
```

Each stage gets its own prompt file. Name the stage files `<slug>-1-<id>.md`, `<slug>-2-<id>.md`, and the outputs `<slug>-1-<id>.out.md`. With `set -e`, exit code 3 from OpenBot stops the chain so the user can answer the bot first.
