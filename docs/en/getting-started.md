**English** | [Русский](../ru/getting-started.md)

# Getting started

`yandex` is a program you type commands into. It talks to Yandex Tracker and
Yandex Wiki, so you can list your issues, read one, comment on it or export a
report without opening a browser.

This page takes you from nothing installed to your first working command. It
assumes you have never used a terminal before. Every step says exactly what to
type and what you should see back.

## What you need

- **A computer running macOS on Apple Silicon (M1 and newer), or Linux on
  x86_64.** Those are the only two builds published. On an Intel Mac, or on a
  Linux machine with an ARM processor, there is no ready-made download and no
  supported way to install; if you need one of those, open an issue at
  <https://github.com/AntonLisovoy/yandex-cli/issues>.
- **On Windows: WSL.** `yandex` does not run on Windows directly. Install the
  Windows Subsystem for Linux, which gives you a real Linux inside Windows, and
  then follow the Linux instructions below inside it. Microsoft's guide:
  <https://learn.microsoft.com/windows/wsl/install>.
- **A Yandex Tracker account** that you can already log into in a browser.
- **An OAuth token and an organization id.** These are two short strings that
  prove to Tracker who you are and which organization you are asking about. You
  do not have them yet; steps 4 and 5 below get them.

## 1. Open a terminal

The terminal is a window where you type commands instead of clicking.

- **macOS:** press `Cmd`+`Space`, type `Terminal`, press `Enter`.
- **Linux:** press `Ctrl`+`Alt`+`T` on most desktops. If nothing happens, open
  the applications menu and search for `Terminal`.

A window opens with a line of text ending in something like `$` or `%`. That is
the *prompt*: it means the terminal is waiting. You type a command after it and
press `Enter` to run it. When the command finishes, the prompt comes back.

## 2. Install

There are two ways to install, and you only need one. If you are on a Mac and
already use Homebrew, use Homebrew. Otherwise use the shell installer.

### Homebrew (macOS)

Homebrew is a package manager - a program whose job is installing other
programs - and the one most Mac developers use. If you do not have it, its own
one-line install command is on <https://brew.sh>.

```bash
brew install AntonLisovoy/tap/yandex-cli
```

### Shell installer (macOS and Linux)

Copy this whole line, paste it after the prompt, and press `Enter`:

```bash
curl -LsSf https://raw.githubusercontent.com/AntonLisovoy/yandex-cli/main/install.sh | sh
```

It downloads the build for your machine, checks the download against the
published SHA256 checksum and refuses to continue if they do not match, unpacks
it into `~/.local/share/yandex-cli/<version>`, and links `~/.local/bin/yandex`
to it. `~` is your home folder, so both live under it; nothing system-wide is
installed and no password is asked for.

It prints two lines naming the version it fetched. Yours will carry whatever
the current release is - for example:

```
Downloading yandex-cli-1.0.0-macos-arm64...
Installed yandex 1.0.0 to /Users/you/.local/bin/yandex
```

Your shell - the program that reads what you type in the terminal - only finds
commands in the folders on a list it keeps, called PATH. If `~/.local/bin` is
not on that list, the installer says so and gives you the line to add:

```
Note: /Users/you/.local/bin is not on your PATH. Add it:
  export PATH="/Users/you/.local/bin:$PATH"
```

Running that line makes `yandex` work in the window you have open now, but not
in the next one. To make it permanent, see
[the troubleshooting page](troubleshooting.md#the-command-is-not-found).

## 3. Check that it worked

Type this and press `Enter`:

```bash
yandex --version
```

You should see the version you just installed, in this shape - the numbers
themselves depend on when you installed:

```
yandex, version 1.0.0
```

> **Got `command not found: yandex` instead?** The program is installed, but
> your shell does not know where to look for it - that is the PATH note from
> the previous step. Fix it on
> [the troubleshooting page](troubleshooting.md#the-command-is-not-found).

## 4. Get an OAuth token

An OAuth token is a long string that lets `yandex` act in Tracker on your
behalf. You create it once, in the browser, and Yandex's own page is the
instruction that stays correct as their interface changes:

<https://yandex.ru/support/tracker/ru/concepts/access>

Follow it in another tab and come back with what it gives you: a long string
starting with `y0_`. That is the whole of what this guide needs from it.

**Treat it exactly like a password.** Anyone holding it can read and change
everything you can in Tracker. Do not paste it into a chat, an issue, a
screenshot or a git commit. If you think it has leaked, revoke the application
at <https://oauth.yandex.ru> and issue a new token.

## 5. Find your organization id

Tracker needs to know which organization you are asking about. There are two
kinds of id and **exactly one of them applies to you**:

| Your organization | Setting to use |
|---|---|
| Managed in Yandex Cloud | `TRACKER_CLOUD_ORG_ID` (`--cloud-org-id`) |
| Yandex 360 or on-premise | `TRACKER_ORG_ID` (`--org-id`) |

Where to look:

- **In Tracker.** Open <https://tracker.yandex.ru/admin/orgs>, or click
  *Administration → Organizations* in Tracker itself. The page lists your
  organizations; copy the value of the identifier field.
- **In Yandex Cloud.** Open <https://center.yandex.cloud> and log in. The
  organization id is shown under the organization's name on the home page;
  click to the right of it to copy it.

If you are not sure which kind you have, try one on the command line before you
save anything. Passing the token and the id as options leaves nothing behind on
disk, so you can try the other one straight away:

```bash
yandex --token y0_... --org-id 123456 config check
```

```bash
yandex --token y0_... --cloud-org-id bpf1abc2def3ghi4jkl5 config check
```

One of the two answers `✓ Connected as <your name>`. That is the one to save in
step 6. When Tracker refuses the credentials instead, the last line of the error
names the header that was actually sent - `X-Org-ID=...` or
`X-Cloud-Org-ID=...` - so you can see which of the two you just tried.

**Never set both at once.** The CLI stops before it sends anything:

```
  ✗ Both org_id and cloud_org_id are set — the API accepts exactly one.
      Unset TRACKER_ORG_ID or TRACKER_CLOUD_ORG_ID (or pass only one of --org-id / --cloud-org-id).
```

This is why the trial above uses options rather than a saved profile: saving a
profile twice *merges* the two attempts, leaving both ids in it and producing
exactly this error every time. If that has already happened, delete the profile
with `yandex config delete-profile work` and save it again with only the id you
need.

## 6. Save a profile

A profile is the token and the organization id, written once into a file that
`yandex` reads every time. Substitute your own token and id, and use whichever
of the two id options worked in step 5:

```bash
yandex config set-profile work --token y0_... --org-id 123456
```

```bash
yandex config set-profile work --token y0_... --cloud-org-id bpf1abc2def3ghi4jkl5
```

Either one prints:

```
  profile: work
  config_file: /Users/you/.yandex-cli/config.json
  current: True
  saved: True
  ✓ Profile 'work' saved to /Users/you/.yandex-cli/config.json
```

Now check that Tracker accepts it:

```bash
yandex config check
```

It answers with your name and the version you are running - for example:

```
  ✓ Connected as John Doe (j.doe)
  backend: yandex-cli 1.0.0
  api_base_url: https://api.tracker.yandex.net
  wiki_base_url: https://api.wiki.yandex.net
  org_id: 123456
  cloud_org_id: -
```

If that name is yours, you are done configuring. The last two lines show which
kind of id you saved; a Yandex Cloud organization fills in `cloud_org_id` and
leaves `org_id` as `-`.

**Why a profile rather than `export TRACKER_TOKEN=...`?** A variable you export
lives only in the terminal window you typed it in; close the window and it is
gone. A `.env` file is read only when you run `yandex` from the directory that
file sits in, so the same command works in one folder and fails in another. A
profile works everywhere, forever. Both other ways still work and are covered
in [configuration](configuration.md).

To see what the CLI thinks it is using:

```bash
yandex config show
```

The token comes out masked: only its first and last four characters and its
length. The `config_file` and `session_file` lines are not masked and contain
your username, so trim those before pasting the output into a bug report.

## 7. Your first commands

**List the queues you can see.** A queue groups a team's issues and gives them
their key prefix - `TREK`, `OPS` and so on.

```bash
yandex tracker queue list
```

```
  Queues
  ──────
  KEY  │ NAME        │ ID │ DEFAULT TYPE │ DEFAULT PRIORITY
  ─────────────────────────────────────────────────────────
  TREK │ Tracker CLI │ 1  │ Задача       │ Normal
  OPS  │ Operations  │ 2  │ Задача       │ Normal
  2 row(s)
```

**Find your own open issues.** The text after `-q` is a Tracker search query,
the same language the search box in the web interface uses.

```bash
yandex tracker issue find -q "Assignee: me() AND Resolution: empty()"
```

```
  Issues matching 'Assignee: me() AND Resolution: empty()'
  ────────────────────────────────────────────────────────
  KEY    │ SUMMARY                     │ STATUS │ TYPE   │ PRIORITY │ ASSIGNEE │ UPDATED
  ──────────────────────────────────────────────────────────────────────────────────────
  OPS-1  │ Rotate the tokens           │ Открыт │ Задача │ Normal   │ John Doe │ -
  TREK-1 │ Design the CLI command tree │ Открыт │ Задача │ Normal   │ John Doe │ -
  TREK-2 │ Implement the session store │ Открыт │ Задача │ Normal   │ John Doe │ -
  TREK-3 │ Write the export pipeline   │ Открыт │ Задача │ Normal   │ John Doe │ -
  4 row(s)
```

**Read one of them.** Use a key from your own list.

```bash
yandex tracker issue get TREK-1
```

```
  Issue TREK-1
  ────────────
  key: TREK-1
  summary: Design the CLI command tree
  status: Открыт
  type: Задача
  priority: Normal
  assignee: John Doe
  created: -
  updated: -
  version: 1
  tags: ["cli"]
  url: https://tracker.yandex.ru/TREK-1

  Description
  ───────────
Description of TREK-1
```

Retyping `TREK-1` in every command gets old, so the CLI remembers the issue you
are working on. Tell it once:

```bash
yandex session use-issue TREK-1
```

and from then on `yandex tracker issue get` with no key means that issue, until
you point it at another one. The full story is in
[commands](commands.md#the-session-what-the-cli-remembers).

## 8. Interactive mode

Instead of typing `yandex` at the start of every line, you can start it once
and stay inside:

```bash
yandex repl
```

Running `yandex` with no arguments at all does the same thing.

Inside, the prompt looks like `◆ yandex ❯`, and it grows a `[TREK-1]` marker
once you have a current issue. You type commands **without** the `yandex`
prefix: `tracker queue list`, not `yandex tracker queue list`.

Typing `help` lists the groups:

```
  Commands
  ────────
  tracker queue ...     queues: list, get, tags, versions, fields
  tracker field ...     metadata: global, statuses, types, priorities, resolutions
  tracker issue ...     issues: find, get, create, update, transition, close, worklog-*
  tracker board ...     boards and sprints: list, get, create, update
  tracker template ...  issue and comment templates: issue-list, comment-list
  tracker user ...      users: list, search, get, me
  tracker project ...   projects, portfolios, goals, entities
  wiki ...              wiki: page *, grid *, attachment *, comment *, access *, search
  export ...            write issues to json/csv/md
  session ...           status, use-queue, use-issue, history, undo, clear
  config ...            show, check, profiles
  help                  this listing
  quit / exit           leave the REPL
```

`quit`, `exit` or `Ctrl`+`D` leaves and returns you to the ordinary prompt. The
up arrow recalls what you typed before, including from earlier sessions:
history is kept in `~/.yandex-cli/history`.

## Where to go next

- **[Configuration](configuration.md)** - profiles, environment variables, and
  read-only modes for when you do not want anything written back.
- **[Commands](commands.md)** - what the CLI can actually do, grouped by task,
  and how the session works.
- **[AI agents](ai-agents.md)** - handing the CLI to Claude Code, Cursor or
  another agent, and keeping it from doing damage.
- **[Troubleshooting](troubleshooting.md)** - the command is not found, the
  token is rejected, the organization id is wrong.
