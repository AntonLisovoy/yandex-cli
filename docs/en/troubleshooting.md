**English** | [Русский](../ru/troubleshooting.md)

# Troubleshooting

Every message below is the one the CLI actually prints. Find yours, and the
row or paragraph next to it says what it means and what to do.

Errors from the CLI start with a red `✗`. Errors from Yandex are wrapped in a
line of the CLI's own that names the HTTP status. Errors about the *shape* of
your command line - a misspelled option, a value in the wrong form - come from
the argument parser and start with `Error:` instead.

## The command is not found

```
command not found: yandex
```

Your shell - the program reading what you type - looks for commands only in the
folders on a list it keeps, called PATH. This message means `yandex` is not in
any of them. There are two reasons for that.

**The likely one: `~/.local/bin` is not on your PATH.** The shell installer
puts `yandex` there, and on many systems that folder is not on the list. The
installer notices and says so at the end:

```
Note: /Users/you/.local/bin is not on your PATH. Add it:
  export PATH="/Users/you/.local/bin:$PATH"
```

Running that `export` line fixes the terminal window you are in now, and only
that one. To fix it permanently, put the line in the file your shell reads
every time it starts.

For **zsh**, which is the default on macOS:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

For **bash**, which is the default on most Linux distributions:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

On macOS with bash, use `~/.bash_profile` instead of `~/.bashrc`. If you are
not sure which shell you are in, `echo $SHELL` tells you.

Then open a new terminal window - the file is read at startup, so the one you
have open now will not pick it up - and try `yandex --version` again.

**The other one: the install did not finish.** Check whether the file is there
at all:

```bash
ls -l ~/.local/bin/yandex
```

If it exists, you get one line describing it, and the problem is PATH. If
nothing was installed, `ls` reports the file missing instead - the exact
phrasing differs between macOS and Linux, but it always ends in `No such file
or directory`. On macOS:

```
ls: /Users/you/.local/bin/yandex: No such file or directory
```

Run the installer again and read what it prints. A download that failed, a
checksum that did not match or a folder it could not write to all stop it with
a message saying so. The install instructions are in
[getting started](getting-started.md#2-install).

## Credentials and organization

These come from the CLI's own checks, before anything is sent to Yandex. They
all have `"type": "ConfigError"` under `--json`.

| Message | What it means | The fix |
|---|---|---|
| `No Yandex Tracker credentials found.` | No token at all: none on the command line, none in the environment, none in the current profile. | Save a profile with `yandex config set-profile work --token y0_... --org-id ...`, or export `TRACKER_TOKEN`. The message itself lists all three ways. |
| `Both org_id and cloud_org_id are set — the API accepts exactly one.` | Both organization ids are set, and Yandex takes one or the other. Usually a profile saved twice, once with each. | Drop one. If it is in a profile, `yandex config delete-profile work` and save it again with only the id you need. |
| `No organization id found.` | There is a token, but nothing saying which organization to ask about. | Set `TRACKER_ORG_ID` (Yandex 360 or on-premise) **or** `TRACKER_CLOUD_ORG_ID` (Yandex Cloud) - see [getting started](getting-started.md#5-find-your-organization-id). |
| `Profile 'agent' not found in /Users/you/.yandex-cli/config.json. Known profiles: cloud, work` | You asked for a profile by name and there is no such profile. The message lists the ones there are. | Check the spelling against that list, or create it. With no profiles at all the list reads `<none>`. |

The first one prints the ways to fix it in full:

```
  ✗ No Yandex Tracker credentials found.
      Set one of:
        export TRACKER_TOKEN=<OAuth token>       # https://yandex.ru/support/tracker/ru/concepts/access
        export TRACKER_IAM_TOKEN=<IAM token>     # Yandex Cloud
      or pass --token / --iam-token, or save a profile:
        yandex config set-profile default --token ... --org-id ...
```

`yandex config show` tells you what the CLI thinks it is using after all four
configuration layers have been applied, which is usually the fastest way to see
which one is wrong. [Configuration](configuration.md#where-settings-come-from)
explains the layers.

## Errors from the Yandex API

These come back from Yandex itself. The CLI adds the status, keeps whatever the
API said about the cause, and appends what to do about it. Under `--json` they
all have `"type": "BackendError"`, and the exit code is 1.

| Status | Message | What to do |
|---|---|---|
| 401, 403 | `Yandex rejected the credentials (HTTP 401)` | The token is wrong, expired, or belongs to a user without access to this organization. See the note below. |
| 404 | `Not found (HTTP 404): <url>`, or `Issue 'TREK-9' not found, or the token has no access to it.` | The key does not exist - or it does, and your token cannot see it. The two are indistinguishable from outside, on purpose. Check the spelling first, then whether you can open it in a browser. |
| 409 | `Conflict (HTTP 409)` plus `The entity changed since you read it. Re-read it to get the current version/revision and retry.` | Somebody edited the issue, page or table between your reading it and your writing to it. Read it again and repeat the write against the new version. |
| 422 | `The API rejected the payload (HTTP 422)` plus `Check required fields with 'yandex tracker queue fields <QUEUE>'.` | Something in what you sent is not acceptable - most often a field the queue requires and you left out, or a value in the wrong form. The API names the field it objected to; the CLI keeps that text. |
| 429 | `Rate limited by Yandex (HTTP 429)` plus `Retry with a lower page size or after a pause.` | Too many requests too quickly. Lower `--per-page`, drop `--all`, or wait and try again. |
| - | `Cannot reach <address>: <reason>. Check the network, a proxy, or --api-base-url.` | Nothing answered at that address. Check that you are online, that a corporate proxy is not in the way, and that `--api-base-url` has not been pointed somewhere odd. |
| - | `Request timed out after 30.0s. Increase it with --timeout or TRACKER_TIMEOUT.` | Yandex answered too slowly - or the query is genuinely big. Raise the limit with `--timeout 60`, or set `TRACKER_TIMEOUT`. |

**On 401 and 403: the last line names the organization header actually sent.**

```
  ✗ Yandex rejected the credentials (HTTP 401): Unauthorized
      Check TRACKER_TOKEN / TRACKER_IAM_TOKEN and that the token's user has access to this organization.
      Organization header in use: X-Org-ID=123456
```

`X-Org-ID` means the CLI used `TRACKER_ORG_ID`; `X-Cloud-Org-ID` means it used
`TRACKER_CLOUD_ORG_ID`. That single line is the fastest way to spot the most
common cause of a rejection, which is not a bad token at all but the *other*
kind of organization id: a Yandex Cloud organization queried with `--org-id`
is rejected exactly like a wrong password. If the header named is not the one
your organization uses, that is your answer - swap it and try again.

## Access restrictions the CLI applies itself

**These come from your own configuration, not from Yandex.** The CLI refuses
the command before it sends anything. That matters because the wording reads
like a permissions problem on the server, and people go looking in Tracker's
admin pages for a setting that is not there. Nothing is wrong with your
account: something local - a flag, an environment variable, or a profile you
saved - is narrowing what the CLI is allowed to do.

`yandex config show` lists the restrictions currently in force.

**A queue outside the allow-list** (`AccessDenied`):

```
  ✗ Queue 'OPS' is not in the allowed list (TREK). Change TRACKER_LIMIT_QUEUES or --limit-queues to widen access.
```

`TRACKER_LIMIT_QUEUES` or `--limit-queues` is set, and the queue you asked for
is not in it. Queues outside the list are not readable either, so this appears
on reads as well as writes.

**A key that is not an issue key** (`AccessDenied`, though it is really a
typo):

```
  ✗ 'TREK' is not an issue key. Expected the form QUEUE-123.
```

An issue key is the queue, a hyphen and a number. `TREK` on its own is a queue,
and belongs to `yandex tracker queue get`, not `yandex tracker issue get`.

**Read-only mode** (`ReadOnlyError`):

```
  ✗ 'issue create' writes to Yandex Tracker, but the CLI is in read-only mode. Unset TRACKER_READ_ONLY or drop --read-only to allow it.
```

Wiki has its own switch, refused separately:

```
  ✗ 'wiki page create' writes to Yandex Wiki, but wiki write access is disabled. Unset WIKI_READ_ONLY or drop --wiki-read-only to allow it.
```

**One queue held read-only** (`ReadOnlyError`), while the rest stay writable:

```
  ✗ 'issue comment-add' writes to queue 'TREK', which is read-only (TRACKER_READ_ONLY_QUEUES=TREK). Drop it from TRACKER_READ_ONLY_QUEUES or --read-only-queues to allow it.
```

All four settings are described in
[configuration](configuration.md#read-only-and-restricted-modes). Remember that
a restriction can come from a saved profile as easily as from a flag or an
environment variable: `yandex config show` prints the value in force, whichever
of the three set it.

## Session and arguments

**No issue in the session.** A command that needs an issue was given none, and
none is remembered:

```
  ✗ No issue given and no current issue in the session. Pass an issue key or run: session use-issue QUEUE-1
```

Pass the key, or set it once with `yandex session use-issue TREK-42`. The queue
version reads the same way:

```
  ✗ No queue given and no current queue in the session. Pass a queue key or run: session use-queue QUEUE
```

**Nothing to undo.** The undo stack is empty:

```
  ✗ Nothing to undo.
```

Either nothing reversible has been done yet, or the last write was one of the
kinds that cannot be reversed - a transition, a move or a delete. Those are
still recorded: `yandex session history` shows them with `UNDOABLE` set to
`no`. See [commands](commands.md#undo) for the full list of what can be undone.

**`--field` not in `key=value` form.** This one comes from the argument parser,
so it says `Error:` rather than `✗`:

```
Error: Invalid value: 'bad' is not in key=value form (e.g. --field storyPoints=3)
```

Every `--field` takes one `key=value` pair with no space around the `=`. Repeat
the option for a second field: `--field storyPoints=3 --field team=platform`.

**Invalid JSON.** Options that take a JSON payload - `--rows`, `--columns`,
`--permissions`, `--actions` and the like - say where the parser gave up:

```
Error: Invalid value: --rows is not valid JSON: Expecting value: line 1 column 3 (char 2)
```

The usual causes are single quotes where JSON wants double ones, a trailing
comma, or the shell eating your quoting. Wrap the whole value in single quotes
so the shell leaves it alone, and use double quotes inside it:

```bash
yandex wiki grid add-rows g-1 --rows '[{"task": "Ship v1", "owner": "j.doe"}]'
```

The same options accept `@file` to read the payload from a file, which is
easier for anything long. When the file cannot be read, the message names it:

```
Error: Invalid value: Cannot read --rows from rows.json: [Errno 2] No such file or directory: 'rows.json'
```

That is a path problem, not a JSON problem: the path is relative to the
directory you are standing in.

## Export

An export refuses to replace a file that already exists:

```
  ✗ report.csv already exists. Pass --overwrite to replace it.
```

This is deliberate, so a rerun cannot silently destroy the report you were
about to send. Add `--overwrite` when replacing it is what you meant, or write
to a new name:

```bash
yandex export issues -q "Queue: TREK AND Updated: week()" -o report.csv --format csv --overwrite
```

## macOS: "cannot be opened because the developer cannot be verified"

**This applies only if you downloaded an archive from the Releases page in a
browser.** Browsers mark every download with a `com.apple.quarantine` flag, and
macOS refuses to run a quarantined program from an unidentified developer.
`curl` and Homebrew do not set that flag, so if you installed with the one-line
installer or with `brew install`, this is not your problem and you can stop
reading here.

If you did download it in a browser, clear the flag on what you unpacked. The
archive contains a folder named for the version and the machine - for example
`yandex-cli-1.0.0-macos-arm64` - holding `yandex` and the libraries it loads,
so clear the whole folder rather than the one file:

```bash
xattr -dr com.apple.quarantine ~/Downloads/yandex-cli-1.0.0-macos-arm64
```

Substitute the folder you actually unpacked. Then run `yandex` again.

The simpler fix, and the one worth preferring, is to install the normal way
instead - it never picks the flag up in the first place:

```bash
curl -LsSf https://raw.githubusercontent.com/AntonLisovoy/yandex-cli/main/install.sh | sh
```

## Upgrading

With Homebrew:

```bash
brew upgrade yandex-cli
```

Otherwise, run the installer one-liner again. It fetches the current release,
unpacks it beside the old one and repoints `~/.local/bin/yandex` at it:

```bash
curl -LsSf https://raw.githubusercontent.com/AntonLisovoy/yandex-cli/main/install.sh | sh
```

**Your settings survive.** `~/.yandex-cli` is not touched by either route:
profiles, the current issue, the history and the undo stack are all still there
afterwards. Check with `yandex --version` and then `yandex config check`.

**The agent skill does not update itself.** `yandex skill install` copies the
file rather than linking to it, so the copy in your project still describes the
version you had when you ran it. Run the install again after upgrading:

```bash
yandex skill install -y
```

The reason it works that way, and what you lose by forgetting, is in
[AI agents](ai-agents.md#after-upgrading).

## Uninstalling

With Homebrew:

```bash
brew uninstall yandex-cli
```

Otherwise, delete the program and the link to it:

```bash
rm -rf ~/.local/share/yandex-cli ~/.local/bin/yandex
```

Either way, **your settings are left behind on purpose**, so that reinstalling
puts you back where you were. To remove them too:

```bash
rm -rf ~/.yandex-cli
```

That directory holds `config.json`, and `config.json` holds your OAuth token in
clear text. Deleting it is the right thing to do on a machine you are handing
on, and the token itself should be revoked at <https://oauth.yandex.ru> if it
may have been seen by anyone else.

## Still stuck

Start with:

```bash
yandex config show
```

**The token comes out masked** - only its first and last four characters and
its length. The `config_file` and `session_file` lines are not masked and carry
your username, so trim those two before pasting; the rest is safe to publish.

Then open an issue at
<https://github.com/AntonLisovoy/yandex-cli/issues> with three things:

1. That `yandex config show` output.
2. The exact command you ran.
3. The exact message you got back, copied rather than described.

Add `yandex --version` if the report is about behaviour that changed. With
those, the problem is usually reproducible on the first try.
