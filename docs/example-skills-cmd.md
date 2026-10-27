# Example commands for using skills

Skills are reusable instructions that give Pi or Claude Code a focused workflow. You can let the assistant choose a relevant skill from your request, or invoke one explicitly by its name.

The invocation syntax differs by tool:

| Tool | Explicit skill syntax | Example |
|---|---|---|
| Pi | `/skill:<skill-name> <request>` | `/skill:datadog-investigate Investigate this alert: <Datadog URL>` |
| Claude Code | `/<skill-name> <request>` | `/datadog-investigate Investigate this alert: <Datadog URL>` |

Use the skill's name as written in its `SKILL.md` frontmatter. The examples below use skills available in this dotfiles setup.

## Pi

Prefix the request with `/skill:` and the skill name. Pi loads that skill's instructions and passes the rest of the line as your request:

```text
/skill:datadog-investigate Investigate this Datadog alert and identify the likely cause: <Datadog URL>
```

```text
/skill:k8s-triage Triage pod api-7c9d in namespace production; inspect its events and logs and explain why it is restarting.
```

You can also enter `/skill:<skill-name>` by itself to load the skill, then send your request in a follow-up message. Usually, including the request on the same line is quicker.

## Claude Code

Invoke a skill as a slash command using its name, followed by the task:

```text
/datadog-investigate Investigate this Datadog alert and identify the likely cause: <Datadog URL>
```

```text
/k8s-triage Triage pod api-7c9d in namespace production; inspect its events and logs and explain why it is restarting.
```

You can also describe the task normally and let Claude Code select a matching skill, if that skill allows automatic invocation.

## Let the assistant choose

Explicit invocation is optional when a skill is discoverable and its description matches the request. For example, either tool may select the Kubernetes triage skill for:

```text
Why is pod api-7c9d in namespace production restarting? Check its events and logs.
```

For a specific procedure, naming the skill explicitly makes your intent clear.

## Recommended prompt when you want all relevant skills considered

There is no single `/skill:all` command. Use this plain-language prompt in either tool to ask it to consider the full available skill set and apply every skill that fits:

```text
Before working on this, check the skills available to you. Use every skill that is relevant to this task and combine their instructions; don't stop at the first matching skill. Don't use unrelated skills. If you can't access an applicable skill, tell me. Task: <describe the task>
```

For example:

```text
Before reviewing this code, check the skills available to you. Use every skill relevant to a security review and simplify/over-engineering review, and combine their instructions. Don't use unrelated skills. Task: review the changes in this branch.
```

To guarantee a particular skill is requested, invoke it explicitly using the syntax above. A plain-language request asks the assistant to select relevant skills; it does not force every installed skill to run.

## If a skill command is unavailable

- Check that the skill is installed for that tool and that its directory contains `SKILL.md`.
- In this dotfiles setup, Pi skills are under `pi/skills/` and Claude Code skills are under `claude/skills/`, and skills shared as one file by every agent are under `agent/skills/`; shared skills may also be linked into the respective user skill directories.
- In Pi, skill commands use `/skill:<name>`. If a newly added or changed skill is not showing up, reload Pi with `/reload` or start a new session.
- In Claude Code, check the `/` command menu for the skill name; a newly installed skill may require a new session to appear.
