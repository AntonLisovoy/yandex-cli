**English** | [Русский](../ru/ai-agents.md)

# Using the CLI from an AI agent

Coding agents - Claude Code, Cursor, Codex, GitHub Copilot, Gemini CLI - can
run terminal commands. That makes `yandex` something you can hand to one:
"close the issues I fixed this week", "write up the meeting on the team wiki
page", "which of my issues have not moved in a month".

The catch is that an agent has never read this documentation. Left to guess, it
invents options that do not exist and gives up. So the CLI carries its own
manual, written for an agent rather than for you, and installs it where the
agent will find it.

## What the agent skill is

It is a single Markdown file, `SKILL.md`, that ships **inside** the `yandex`
binary. There is nothing to download and nothing to keep in sync by hand.

It describes every command group, the Tracker query language, the `--json`
contract, the discover-before-you-write sequences (ask a queue for its required
fields before creating an issue in it; ask an issue for its transitions before
moving it), which operations `session undo` can reverse, and the failure modes
with the fix for each. Roughly: the whole of
[commands](commands.md) compressed into the form an agent reads best - a table
of commands and a list of worked examples, with no explanation of what a queue
is.

Agents that support skills read files like this one automatically and consult
them when a task looks relevant. The description at the top of the file is what
makes that happen: it lists Tracker and Wiki by name, so a request mentioning
either pulls the skill in.

## Install it

```bash
yandex skill install
```

That copies `SKILL.md` out of the binary into the directory your agent reads
skills from. In a terminal it first asks the two questions covered below; once
you have answered them it prints the file it wrote:

```
Installed the yandex skill to /Users/you/work/.agents/skills/yandex/SKILL.md
```

Run it from the project directory you want the agent to have Tracker access in.
An existing copy is replaced, so running it again is always safe.

### Answering the questions

With no flags, `skill install` asks two questions.

**Which agents should get the skill?** Several can be marked at once:

```
? Which agents should get the skill?
  Space to select · a all · Enter confirm

❯ ◯ claude-code
  ◯ codex
  ◯ copilot
  ◯ cursor
  ◯ gemini
  ◯ universal
```

The `↑` and `↓` arrow keys move the `❯` pointer, `Space` marks the agent it is
on, `a` marks them all (and pressing it again clears them), and `Enter`
confirms. Confirming with nothing marked does nothing but ask again - pick at
least one.

**Where should it go?** One of two, chosen with the arrow keys and `Enter`:

```
? Where should it go?
  ↑↓ to move · Enter confirm

❯ ● This directory only
  ○ The whole user account
```

*This directory only* puts the skill in the project you are standing in, so it
applies to that repository and nothing else. *The whole user account* puts it
under your home directory, where every project sees it. Start with the
directory; widen it later if you find yourself installing it repeatedly.

When the command is run from a script or a pipe rather than a terminal there is
nothing to draw a picker on, so it asks the same two questions as plain text
prompts instead:

```
Which agents should get the skill?
  1. claude-code
  2. codex
  3. copilot
  4. cursor
  5. gemini
  6. universal
Numbers, comma separated [6]:
Install for the whole user account? (no = only this directory) [y/N]:
```

### Skipping the questions

`-a` names an agent (repeat it for several), `-g` means the whole user account,
`--project` means this directory, and `-y` accepts the defaults for anything
left unasked:

```bash
yandex skill install -a claude-code -g -y      # this user, Claude Code
yandex skill install -a cursor -a codex -y     # this directory, two agents
yandex skill install -y                        # this directory, `universal`
yandex skill install --dir ./somewhere/yandex  # an explicit directory
```

`--dir` bypasses the agent layout altogether and writes into the directory you
name, for a tool that keeps its skills somewhere none of the built-in choices
cover.

## Supported agents

| Agent | In a project | For the user account |
|---|---|---|
| `claude-code` | `.claude/skills/yandex/` | `~/.claude/skills/yandex/` |
| `cursor` | `.agents/skills/yandex/` | `~/.cursor/skills/yandex/` |
| `codex` | `.agents/skills/yandex/` | `~/.codex/skills/yandex/` |
| `copilot` | `.agents/skills/yandex/` | `~/.copilot/skills/yandex/` |
| `gemini` | `.agents/skills/yandex/` | `~/.gemini/skills/yandex/` |
| `universal` | `.agents/skills/yandex/` | `~/.config/agents/skills/yandex/` |

**A project install goes to `.agents/skills/yandex/` for every agent except
Claude Code**, which reads `.claude/skills/yandex/`. `.agents/skills/` is a
shared convention, so one install covers Cursor, Codex, Copilot and Gemini at
once - which is why naming several of them writes a single file and prints a
single line:

```bash
yandex skill install -a cursor -a codex -y
```

```
Installed the yandex skill to /Users/you/work/.agents/skills/yandex/SKILL.md
```

`universal` is the same directory under a name that promises nothing about
which agent reads it. It is the default when you press `Enter` through the
questions, and what `-y` alone picks.

## Any other agent

Any tool that takes instructions as text can be given the skill, whatever
format it wants them in. Print it:

```bash
yandex skill show
```

Redirect it into whatever file your tool reads:

```bash
yandex skill show > AGENTS.md
```

Or find the file on disk, to copy, symlink or paste from:

```bash
yandex skill path
```

It prints one absolute path, inside the installed bundle. Read it, do not edit
it: the next upgrade installs into its own directory, and an edit made there
stays behind with the old version.

## After upgrading

`skill install` **copies** the file; it does not link to it. The copy in your
project therefore describes the version of the CLI that was installed on the
day you ran it, and it will keep describing that version forever.

This is deliberate. Each release unpacks into its own directory, so a symbolic
link would still resolve after an upgrade - and would quietly go on serving the
old skill, which is a worse failure than a stale copy you can see.

So after every upgrade of the CLI, run the install again:

```bash
yandex skill install -y
```

Nothing breaks if you forget: the agent works from a slightly older list of
commands. But a command added in the new version is one the agent does not know
exists.

## Keeping an agent safe

An agent driving `yandex` has exactly the access your token has. It can close
issues, delete wiki pages and rewrite a queue's permissions - not because it
means to, but because it misread a request. Two of those are things
`yandex session undo` cannot reverse.

The fix is to give the agent a narrower CLI than the one you use:

- **`--read-only` / `TRACKER_READ_ONLY`** refuses every Tracker write, so an
  agent that summarises, reports or searches loses nothing.
- **`--wiki-read-only` / `WIKI_READ_ONLY`** does the same for Wiki, separately,
  so an agent may file issues without touching your pages.
- **`--limit-queues` / `TRACKER_LIMIT_QUEUES`** hides every queue but the ones
  you name, so an agent sent after one team's work cannot wander into another's.
- **`--read-only-queues` / `TRACKER_READ_ONLY_QUEUES`** keeps the queues you
  name readable but refuses writes to them, so an agent can research a
  production queue without changing it.

Save a profile that is read-only and hand the agent that:

```bash
yandex config set-profile agent --token y0_exampletokenvalue --org-id 123456 --read-only --limit-queues TREK --not-current
```

`--not-current` keeps your own work on your own profile. Three of the four
settings can live in a profile like this; **`--read-only-queues` cannot** -
`set-profile` has no option for it, so that one has to come from the flag or
from `TRACKER_READ_ONLY_QUEUES` in the agent's environment. The agent then runs
every command through the restricted profile:

```bash
yandex --profile agent tracker issue find -q "Queue: TREK AND Updated: week()"
```

and a write comes back refused, in words that say exactly what stopped it:

```
  ✗ 'issue comment-add' writes to Yandex Tracker, but the CLI is in read-only mode. Unset TRACKER_READ_ONLY or drop --read-only to allow it.
```

**A profile is a guard rail, not a sandbox.** An agent that can run
`yandex config set-profile` can also lift the restriction, and one that can
edit your shell can drop `--profile agent`. When you need the restriction to
actually hold, set it in the environment the agent itself runs in - a
`TRACKER_READ_ONLY=1` in the agent's own environment, or a container started
with it - where the agent has no reason to look and no command that changes it
from the inside.

The four settings are covered in full, with the message each one produces, in
[configuration](configuration.md#read-only-and-restricted-modes).
