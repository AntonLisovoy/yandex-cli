**English** | [Русский](../ru/configuration.md)

# Configuration

`yandex` needs to know two things before it can do anything: who you are (a
token) and which organization to ask about (an id). This page covers every way
to tell it, where it keeps what you tell it, and how to lock it down so it can
only read.

If you just want to get going, [getting started](getting-started.md) has the
short version.

## Where settings come from

Four layers. Each layer overrides the ones before it - the last one with an
opinion wins.

| # | Layer | Example |
|---|---|---|
| 1 | Built-in defaults | `api_base_url=https://api.tracker.yandex.net`, `wiki_base_url=https://api.wiki.yandex.net`, `timeout=30.0` |
| 2 | The current profile | `~/.yandex-cli/config.json` |
| 3 | Environment variables | `export TRACKER_TOKEN=y0_...` |
| 4 | Command-line flags | `yandex --token y0_... config check` |

So a `TRACKER_ORG_ID` exported in your shell beats the org id saved in the
profile, and `--org-id` on the command line beats both.

> **The one exception.** Passing `--profile NAME` explicitly puts that profile
> **above** the environment - the reverse of the order in the table. Asking for
> a profile by name means you want that profile, not whatever happens to be
> exported in this window. Without `--profile`, the current profile stays at
> layer 2 and the environment wins.

To see the result of all four layers, ask:

```bash
yandex config show
```

## Profiles

A profile is a named set of settings kept in a file, so you type them once
instead of every time. It is the recommended way to hold credentials: unlike an
exported variable, which lives only in the terminal window you typed it in, and
unlike a `.env` file, which is read only in the directory it sits in, a profile
works from any directory in any window until you change it.

You can have several - one per organization, or one read-only profile for
handing to a script - and switch between them by name.

### Creating and switching

**Create one.** `set-profile` creates it if it does not exist and updates the
fields you name if it does. `y0_exampletokenvalue` stands in for your own token
throughout this page:

```bash
yandex config set-profile work --token y0_exampletokenvalue --org-id 123456
```

```
  profile: work
  config_file: /Users/you/.yandex-cli/config.json
  current: True
  saved: True
  ✓ Profile 'work' saved to /Users/you/.yandex-cli/config.json
```

Saving a profile also makes it the current one. Pass `--not-current` to add a
profile without switching to it:

```bash
yandex config set-profile cloud --token y0_exampletokenvalue --cloud-org-id bpf1abc2def3ghi4jkl5 --not-current
```

Besides the credentials, `set-profile` accepts `--api-base-url`,
`--wiki-base-url`, `--limit-queues`, `--read-only` / `--no-read-only` and
`--wiki-read-only` / `--no-wiki-read-only`.

**List them.** `CURRENT` marks the one in use; `TOKEN` says whether a
credential is stored, never what it is:

```bash
yandex config list-profiles
```

```
  Profiles
  ────────
  NAME  │ CURRENT │ ORG                  │ API │ TOKEN
  ────────────────────────────────────────────────────
  cloud │ no      │ bpf1abc2def3ghi4jkl5 │ -   │ set
  work  │ yes     │ 123456               │ -   │ set
  2 row(s)
```

**Switch.** This is permanent until you switch again:

```bash
yandex config use-profile cloud
```

```
  profile: cloud
  current: True
  ✓ Active profile: cloud
```

**Use one for a single command** without switching. `--profile` goes before the
command, because it is a setting for the whole program rather than for that one
command:

```bash
yandex --profile cloud tracker queue list
```

**Delete one.** If you delete the current profile, another one becomes current -
if you have another. Delete your last profile and nothing is current, so the CLI
falls back to the environment:

```bash
yandex config delete-profile cloud
```

```
  profile: cloud
  deleted: True
  ✓ Profile 'cloud' deleted
```

### Where profiles are stored

In `~/.yandex-cli/config.json`. It is a JSON file with a `current` key naming
the active profile and a `profiles` object holding the rest:

```json
{
  "current": "work",
  "profiles": {
    "work": {
      "limit_queues": [],
      "org_id": "123456",
      "read_only_queues": [],
      "token": "y0_exampletokenvalue"
    }
  }
}
```

**The token is stored in clear text.** Nothing encrypts it. That is the same
bargain as a `~/.netrc` or a `~/.aws/credentials` file, and it means the file is
worth protecting: it should not be in a backup you share, in a synced folder
other people can read, or in a git repository. On a machine other people can log
into, restrict it with `chmod 600 ~/.yandex-cli/config.json`.

Setting `YANDEX_CLI_HOME` moves the whole directory - profiles, session and
history together - somewhere else:

```bash
YANDEX_CLI_HOME=/secure/volume/yandex yandex config check
```

## Environment variables

An environment variable is a setting attached to a running program rather than
to a file. Reach for one when a file on disk is the wrong place to put the
token - which is mostly when something other than you is doing the running:

- **CI pipelines** - the servers that build and test your code automatically.
  They hand each run its secrets from a vault, and writing a token into a file
  there would put it in the repository for everyone to read.
- **Containers** - prepackaged, disposable copies of a program. The package is
  shared with everyone; the credentials must not be.
- **A one-off shell** - a single terminal window in which you want to run
  something as a different user, or against a different organization, without
  disturbing your saved profiles.

If none of those describe you, use a profile.

Set one for a single command by putting it in front of the command:

```bash
TRACKER_ORG_ID=654321 yandex tracker queue list
```

or for the rest of the terminal window with `export`:

```bash
export TRACKER_TOKEN=y0_...
export TRACKER_ORG_ID=123456
yandex config check
```

A variable set to an empty string is treated as not set at all, so
`TRACKER_TOKEN=` does not blank out the token in your profile - it just leaves
the profile's value in place.

### The full list

| Variable | What it does |
|---|---|
| `TRACKER_TOKEN` | OAuth token. One credential is required. |
| `TRACKER_IAM_TOKEN` | Yandex Cloud IAM token, as an alternative to the OAuth one. |
| `TRACKER_ORG_ID` | Organization id for Yandex 360 / on-premise Tracker. |
| `TRACKER_CLOUD_ORG_ID` | Organization id for a Yandex Cloud organization. Set exactly one of the two. |
| `TRACKER_API_BASE_URL` | Tracker API address. Default `https://api.tracker.yandex.net`. |
| `WIKI_API_BASE_URL` | Wiki API address. Default `https://api.wiki.yandex.net`. |
| `TRACKER_READ_ONLY` | Boolean. Refuse every Tracker command that writes. |
| `WIKI_READ_ONLY` | Boolean. Refuse every Wiki command that writes. |
| `TRACKER_LIMIT_QUEUES` | Comma-separated queue keys. Only these queues are reachable at all. |
| `TRACKER_READ_ONLY_QUEUES` | Comma-separated queue keys that stay readable but refuse writes. |
| `TRACKER_TIMEOUT` | Seconds to wait for the API. Default `30.0`. |
| `YANDEX_CLI_HOME` | Directory holding config, session and history. Default `~/.yandex-cli`. |
| `YANDEX_CLI_SESSION` | Path to the session file alone, overriding the one inside `YANDEX_CLI_HOME`. |
| `NO_COLOR` | Set to any non-empty value to turn off coloured output. |
| `YANDEX_CLI_NO_COLOR` | The same, without affecting other programs. |

The boolean variables accept `1`, `true`, `yes` or `on`, in any casing.
Anything else, including `0` and `false`, means off. `NO_COLOR` and
`YANDEX_CLI_NO_COLOR` are the exception: they are checked for being set at all,
so `NO_COLOR=0` also turns colour off.

Queue keys are compared case-insensitively - `TRACKER_LIMIT_QUEUES="trek, ops"`
and `TRACKER_LIMIT_QUEUES=TREK,OPS` mean the same thing.

The `TRACKER_*` names are deliberately the same ones the
[yandex-tracker-mcp](https://github.com/aikts/yandex-tracker-mcp) server reads,
so a single `.env` configures both the CLI and the MCP server.

### Using a .env file

If a file named `.env` sits in the directory you run `yandex` from, its
`KEY=value` lines are read as environment variables:

```
TRACKER_TOKEN=y0_...
TRACKER_ORG_ID=123456
```

Two things about this are easy to get wrong:

- **It is read from the current directory, not from the file's project.** Run
  the same command one directory up and the `.env` is not found, so the command
  behaves differently - usually by falling back to your profile, sometimes by
  failing outright. If a command works in one folder and not another, this is
  almost always why.
- **It never overrides a variable already exported in your shell.** The file
  fills in what is missing. An `export TRACKER_TOKEN=...` you typed earlier in
  the window wins over the `.env`.

To read a file somewhere else, name it:

```bash
yandex --env-file ~/secrets/tracker.env config check
```

Add `.env` to your `.gitignore`. It holds a token.

## Files on disk

Everything the CLI keeps lives in one directory, `~/.yandex-cli` unless
`YANDEX_CLI_HOME` says otherwise:

| File | What is in it |
|---|---|
| `~/.yandex-cli/config.json` | Profiles and which one is current. Contains tokens. |
| `~/.yandex-cli/session.json` | The current queue and issue, the last result, the history of writes, and the undo stack. |
| `~/.yandex-cli/history` | What you typed in interactive mode, so the up arrow works across sessions. |

The two JSON files behave differently when damaged, on purpose:

- **A corrupt `session.json` is not an error.** The session is a convenience,
  so an unreadable one is discarded and the CLI starts with an empty session:
  no current issue, no history. Your commands still run.
- **A corrupt `config.json` is an error**, because guessing about credentials
  would be worse than stopping. The message names the file so you can fix or
  delete it:

```
  ✗ Profile store /Users/you/.yandex-cli/config.json is not valid JSON: Expecting value: line 1 column 1 (char 0)
```

Deleting `session.json` or `history` is safe: you lose the current issue, the
undo stack and the recalled command lines, nothing else. Deleting `config.json`
loses your saved profiles, and you would create them again with `set-profile`.

## Read-only and restricted modes

Four settings narrow what the CLI is allowed to do. Each has a flag and an
environment variable, and each refuses the command with an explanation rather
than failing quietly.

**`--read-only` / `TRACKER_READ_ONLY`** refuses every Tracker command that
changes anything - creating issues, editing them, commenting, transitioning.
Reading is untouched.

```bash
yandex --read-only tracker issue comment-add TREK-1 --text "hello"
```

```
  ✗ 'issue comment-add' writes to Yandex Tracker, but the CLI is in read-only mode. Unset TRACKER_READ_ONLY or drop --read-only to allow it.
```

**`--wiki-read-only` / `WIKI_READ_ONLY`** does the same for Wiki, separately, so
you can allow Tracker writes while keeping pages untouchable.

```
  ✗ 'wiki page create' writes to Yandex Wiki, but wiki write access is disabled. Unset WIKI_READ_ONLY or drop --wiki-read-only to allow it.
```

**`--limit-queues` / `TRACKER_LIMIT_QUEUES`** is an allow-list of queue keys.
Queues outside it are not readable either:

```bash
yandex --limit-queues TREK tracker queue get OPS
```

```
  ✗ Queue 'OPS' is not in the allowed list (TREK). Change TRACKER_LIMIT_QUEUES or --limit-queues to widen access.
```

**`--read-only-queues` / `TRACKER_READ_ONLY_QUEUES`** is narrower: the listed
queues stay fully readable, but writing to them is refused. Use it to protect a
production queue while leaving the rest of the organization writable.

```bash
yandex --read-only-queues TREK tracker issue comment-add TREK-1 --text "hello"
```

```
  ✗ 'issue comment-add' writes to queue 'TREK', which is read-only (TRACKER_READ_ONLY_QUEUES=TREK). Drop it from TRACKER_READ_ONLY_QUEUES or --read-only-queues to allow it.
```

The obvious use for all four is handing the CLI to something that is not you: a
script, a CI job, or an AI agent. A profile saved with `--read-only`, or a
container with `TRACKER_READ_ONLY=1` in its environment, turns every destructive
command into a refusal.

They are a guard rail, not a sandbox. The environment sits above the profile
(see [where settings come from](#where-settings-come-from)), so anything that
can edit the environment or the config file can lift the restriction. Against
an AI agent the reliable version is to set the variable in the environment the
agent itself runs in, where it has no reason to look. See
[AI agents](ai-agents.md#keeping-an-agent-safe).

## Several organizations

Give each organization its own profile:

```bash
yandex config set-profile acme --token y0_exampletokenvalue --org-id 123456
yandex config set-profile cloud --token y0_exampletokenvalue --cloud-org-id bpf1abc2def3ghi4jkl5 --not-current
```

Switch when you change context for a while:

```bash
yandex config use-profile cloud
```

Or reach into the other one for a single command, leaving the current profile
alone:

```bash
yandex --profile cloud tracker queue list
```

Remember that `--profile` also outranks the environment, so it does the right
thing even in a shell that has `TRACKER_ORG_ID` exported for something else.

If you are ever unsure which organization a command just went to,
`yandex config check` names it - the `backend` line carries whichever version
you are running:

```
  ✓ Connected as John Doe (j.doe)
  backend: yandex-cli 1.0.0
  api_base_url: https://api.tracker.yandex.net
  wiki_base_url: https://api.wiki.yandex.net
  org_id: 123456
  cloud_org_id: -
```
