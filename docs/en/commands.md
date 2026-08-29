**English** | [Русский](../ru/commands.md)

# Commands

This page is the guided tour: how a command line is put together, what the
groups of commands are for, the one feature you cannot discover from `--help` -
the session - and a set of worked recipes for the things people actually do.

If you have not installed and configured the CLI yet, start with
[getting started](getting-started.md).

## How a command is built

Every command has the same shape:

```
yandex [global flags] <domain> <group> <command> [arguments]
```

`yandex tracker issue get TREK-1` is *domain* `tracker`, *group* `issue`,
*command* `get`, *argument* `TREK-1`. A few things - `config`, `session`,
`export`, `skill`, `repl` - have no domain, because they are not about Tracker
or Wiki: `yandex session status`.

> **Global flags go before the domain.** This is the mistake everyone makes
> once. `yandex --json tracker issue find -q "Queue: TREK"` works.
> `yandex tracker issue find --json -q "Queue: TREK"` does not, and answers
> with:
>
> ```
> Usage: yandex tracker issue find [OPTIONS]
> Try 'yandex tracker issue find --help' for help.
>
> Error: No such option '--json'.
> ```
>
> A global flag - `--json`, `--profile`, `--token`, `--read-only`, `--timeout`
> and the rest of the list in `yandex --help` - configures the whole program,
> so it is attached to the program's own name, not to the command at the end of
> the line.

`--help` works at every level, and `-h` is the short form of it. Ask the level
you are unsure about:

```bash
yandex --help
yandex tracker --help
yandex tracker issue --help
yandex tracker issue find --help
```

Each one lists what is available *below* that point, so four questions get you
from "what is there" to "what does this command take".

## Command groups

There are two domains - Tracker and Wiki - plus a handful of commands that
belong to the CLI itself rather than to either API.

### Tracker

Everything under `yandex tracker <group> ...`:

| Group | What it is for |
|---|---|
| `queue` | Queues: their metadata, fields, components, permissions and macros. |
| `issue` | Issues: search, read, create, edit, transition, close, comments, checklists, links, attachments and worklogs. |
| `attachment` | Uploading a file on its own, before anything references it. |
| `board` | Agile boards, their columns and the sprints on them. |
| `sprint` | Sprints: read, create, start, archive. |
| `user` | The people in the organization. |
| `field` | Organization-wide metadata: fields, statuses, types, priorities, resolutions. |
| `entity` | Projects, portfolios and goals, through the newer entities API. |
| `project` | Projects of the older `v3/projects` resource. |
| `automation` | Queue triggers and auto-actions. |
| `template` | Issue and comment templates configured in Tracker's settings. |

### Wiki

Everything under `yandex wiki <group> ...`:

| Group | What it is for |
|---|---|
| `page` | Wiki pages: read, create, update, append, delete, recover, clone. |
| `grid` | Dynamic tables: their rows, columns and cells. |
| `access` | Who may read and edit a page. |
| `attachment` | Files attached to a page. |
| `upload` | Multipart upload sessions, for a file too big to send in one go. |
| `comment` | Page comments and their threads. |
| `operation` | The status of a long-running copy started by `page clone` or `grid clone`. |

Two Wiki commands sit directly under `yandex wiki`, because they are not about
one page:

| Command | What it is for |
|---|---|
| `search` | Search pages and files across the whole wiki. |
| `whoami` | Show which wiki user the current token belongs to. |

### Shared

These have no domain in front of them:

| Group | What it is for |
|---|---|
| `config` | Credentials, profiles, and checking that Yandex accepts them. |
| `session` | The current queue and issue, the history of writes, and undo. |
| `export` | Writing a search result to a file as JSON, CSV or Markdown. |
| `skill` | The agent skill file that ships inside the binary. |
| `repl` | Interactive mode, also what you get by running `yandex` with nothing after it. |
| `completion` | The Tab-completion script for bash, zsh or fish. |

## The session: what the CLI remembers

`yandex` is not a program that forgets everything the moment it exits. Between
one command and the next it keeps:

- **The current queue** - so a command that needs a queue can be given none.
- **The current issue** - so `yandex tracker issue get` with no key still means
  something.
- **The last result set** - the keys of the last listing you ran.
- **A history of writes** - every command that changed something, with when and
  what.
- **An undo stack** - the subset of those writes that can be reversed.

All of it lives in one file, `~/.yandex-cli/session.json`. Deleting that file
is harmless: you lose the current issue, the history and the undo stack, and
nothing else. (`YANDEX_CLI_SESSION` points at a different file, and
`YANDEX_CLI_HOME` moves the whole directory; see
[configuration](configuration.md#the-full-list).)

### Setting the current queue and issue

Name the issue you are working on once:

```bash
yandex session use-issue TREK-42
```

```
  current_issue: TREK-42
  current_queue: TREK
  ✓ Current issue: TREK-42
```

Notice the second line: setting the issue also sets the queue, taken from the
key's prefix. `TREK-42` is in `TREK`, so the CLI does not need to be told.

To set a queue without picking an issue in it:

```bash
yandex session use-queue TREK
```

```
  current_queue: TREK
  ✓ Current queue: TREK
```

From then on the issue key argument is optional almost everywhere.
`yandex tracker issue get`, `yandex tracker issue comments`,
`yandex tracker issue comment-add -t "..."` all act on `TREK-42`. Writing `-`
in place of the key means the same thing, explicitly - useful when you want a
reader of your script to see that a current issue is being relied on:

```bash
yandex tracker issue get -
```

To see what is remembered:

```bash
yandex session status
```

```
  Session
  ───────
  path: /Users/you/.yandex-cli/session.json
  current_queue: TREK
  current_issue: TREK-42
  last_result: -
  history_entries: 0
  undo_available: 0
  next_undo: -
```

Run `use-queue` or `use-issue` with no argument to clear:

```bash
yandex session use-queue
```

```
  current_queue: -
  ✓ Current queue: <none>
```

Once the issue is cleared too, a command that needs one and is given none says
so rather than guessing. This is what `yandex tracker issue get` prints with an
empty session:

```
  ✗ No issue given and no current issue in the session. Pass an issue key or run: session use-issue QUEUE-1
```

### The history

Every command that writes something is recorded:

```bash
yandex session history --limit 20
```

```
  History
  ───────
  WHEN                      │ OP           │ SUMMARY        │ UNDOABLE
  ────────────────────────────────────────────────────────────────────
  2026-08-29T08:01:15+00:00 │ issue.update │ updated TREK-1 │ yes
  1 row(s)
```

A record holds the UTC timestamp, the operation, the arguments it was given, a
one-line summary, and whether it can be undone. **Every write goes in,
including the ones undo cannot reverse** - that is the point of it. When you
need to know what a script did to Tracker half an hour ago, the history answers
even where undo cannot. The last 200 entries are kept.

### Undo

`undo` reverses the most recent reversible write. Look before you leap:
`--dry-run` shows what would be reversed and changes nothing.

```bash
yandex session undo --dry-run
```

```
  Would undo
  ──────────
  ts: 2026-08-29T08:01:15+00:00
  op: issue.update
  issue: TREK-1
  restore: {"summary": "Design the CLI command tree"}
  version: 1
```

`restore` is what will be put back. If that is what you wanted, do it:

```bash
yandex session undo
```

```
  undone: issue.update
  issue: TREK-1
  issue_state: {"createdAt": "2026-08-01T10:00:00Z", "updatedAt": "2026-08-16T09:00:00Z", "createdBy": {"id": "j.doe", "display": "John Doe", "cloudUid": null, "passportUid": null}, "version": 3, "key": "TREK-1",...
  ✓ Undone: issue.update
```

The `issue_state` line is the issue as it stands after the reversal. Any
structured value longer than 200 characters is cut short with `...` in the
table view; `--json` prints it whole.

Each `undo` reverses one step, and the stack holds the last 50. With an empty
stack:

```
  ✗ Nothing to undo.
```

These operations are reversible, all under `tracker`:

`issue update`, `issue worklog-add`, `issue comment-add`,
`issue checklist-add`, `issue link`, `issue remote-link-add`,
`issue attachment-upload`, `board create`, `board column-add`,
`sprint create`, `entity create`, `entity comment-add`, `entity link`,
`project create`, `queue create`, `queue macro-create`.

**Status transitions, moves and deletions are recorded in the history but
cannot be undone.** Closing an issue, moving it to another queue or deleting
anything is a decision the CLI will not take back for you. If you need to
reverse one, do it deliberately with the opposite command.

## Recipes

The rest of this page is the small set of sequences that cover most days.
Each one is complete: you can copy it, substitute your own queue and issue
keys, and it works.

### Find the issues assigned to me

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

The text after `-q` is written in the **Tracker query language** - the same
language the search box in the web interface uses, so anything you can search
for there you can search for here. `me()` is you, `empty()` matches an unset
field, and `Queue: TREK AND Updated: week()` is the other pattern you will use
constantly. Yandex documents the whole language, with every field name and
function, at
<https://yandex.ru/support/tracker/ru/user/query-filter>.

Three options control how much comes back:

- `--order` sorts on the server: `--order '-updatedAt'` is newest first, and
  the leading `-` is what reverses it.
- `--all` walks every page of results instead of just the first.
- `--limit N` stops after N issues, which is what keeps `--all` from fetching
  a thousand of them.

```bash
yandex tracker issue find -q "Queue: TREK" --order '-updatedAt' --all --limit 2
```

```
  Issues matching 'Queue: TREK'
  ─────────────────────────────
  KEY    │ SUMMARY                     │ STATUS │ TYPE   │ PRIORITY │ ASSIGNEE │ UPDATED
  ──────────────────────────────────────────────────────────────────────────────────────
  TREK-1 │ Design the CLI command tree │ Открыт │ Задача │ Normal   │ John Doe │ -
  TREK-2 │ Implement the session store │ Открыт │ Задача │ Normal   │ John Doe │ -
  2 row(s)
```

### Create an issue

Queues differ in what they demand. Ask first, so the create does not bounce:

```bash
yandex tracker queue fields TREK --required-only
```

```
  Fields of TREK
  ──────────────
  ID      │ NAME    │ TYPE   │ REQUIRED │ KEY
  ───────────────────────────────────────────────
  summary │ Summary │ string │ yes      │ summary
  1 row(s)
```

This queue only insists on a summary, so the create is short:

```bash
yandex tracker issue create TREK -s "Rotate the deploy key" -d "The key expires on Friday."
```

```
  Issue created
  ─────────────
  key: TREK-102
  summary: Rotate the deploy key
  status: Открыт
  url: https://tracker.yandex.ru/TREK-102
  ✓ Created TREK-102
```

`-s` is the title and `-d` the description, which is Markdown. Add the type,
the assignee and the priority as you need them. `--type` takes a numeric id
rather than a name, so run `yandex tracker field types` first and read the id
out of its `ID` column - that is where the `2` below comes from:

```bash
yandex tracker issue create TREK -s "Rotate the deploy key" --type 2 --assignee j.doe --priority critical
```

Anything the queue asks for that has no option of its own goes in with
`--field key=value`, repeated as often as you need. The value is read as JSON
when it can be, and as plain text otherwise, so numbers and lists work:

```bash
yandex tracker issue create TREK -s "Rotate the deploy key" --field storyPoints=3 --field tags='["ops","security"]'
```

If a required field is missing, Yandex says so and names it - see
[troubleshooting](troubleshooting.md#errors-from-the-yandex-api).

### Comment on an issue

```bash
yandex tracker issue comment-add TREK-1 -t "Ready for review."
```

```
  Comment on TREK-1
  ─────────────────
  createdAt: 2026-08-16T09:00:00Z
  updatedAt: 2026-08-16T09:00:00Z
  createdBy: {"id": "j.doe", "display": "John Doe", "cloudUid": null, "passportUid": null}
  id: 601
  longId: c601
  text: Ready for review.
  ✓ Added comment 601 to TREK-1
```

`--summon` pulls someone into the conversation - the same as typing their name
into a comment in the web interface, and they are notified:

```bash
yandex tracker issue comment-add TREK-1 -t "Ready for review." --summon a.smith
```

A comment of any length is painful to type between quotes, and a shell will
mangle it the first time you use an apostrophe. Write it in a file and pass the
file with `@`:

```bash
yandex tracker issue comment-add TREK-1 -t @comment.md
```

The `@` is the CLI's own convention, not the shell's: `-t @comment.md` means
"read the text out of `comment.md`". The same works for
`yandex wiki page create --content @notes.md` and for any option that takes a
JSON payload.

### Move an issue through the workflow and close it

An issue cannot go from any status to any other - each queue has a workflow
that says what is allowed from where. Ask the issue what it can do right now:

```bash
yandex tracker issue transitions TREK-1
```

```
  Transitions of TREK-1
  ─────────────────────
  ID             │ DISPLAY  │ TO       │ TO KEY
  ─────────────────────────────────────────────────
  start_progress │ В работу │ В работе │ inProgress
  close          │ Закрыть  │ Закрыт   │ closed
  2 row(s)
```

The `ID` column is what `yandex tracker issue transition --to` takes.

Closing also needs a *resolution* - the reason it is closed. Those are
organization-wide, not per issue:

```bash
yandex tracker field resolutions
```

```
  Resolutions
  ───────────
  ID │ KEY     │ NAME
  ──────────────────────────────────
  1  │ fixed   │ Решен
  2  │ wontFix │ Не будет исправлено
  2 row(s)
```

Now close it, with the reason and a note for whoever reads it later:

```bash
yandex tracker issue close TREK-1 --resolution fixed --comment "Deployed in 1.0.0."
```

```
  Transitions now available for TREK-1
  ────────────────────────────────────
  ID             │ DISPLAY  │ TO
  ────────────────────────────────────
  start_progress │ В работу │ В работе
  close          │ Закрыть  │ Закрыт
  2 row(s)
  ✓ Closed TREK-1 with resolution 'fixed'
```

Discover, then act. Guessing a transition id or a resolution key is the usual
way to get a `422` back from the API, and neither is something `--help` can
tell you: they are your organization's, not the CLI's.

Closing an issue **cannot be undone** by `yandex session undo`. To reopen one,
transition it back deliberately.

### Log time

```bash
yandex tracker issue worklog-add TREK-1 --duration PT1H30M --comment "Code review."
```

```
  Worklog added to TREK-1
  ───────────────────────
  createdAt: 2026-08-16T09:00:00Z
  updatedAt: 2026-08-16T09:00:00Z
  createdBy: {"id": "j.doe", "display": "John Doe", "cloudUid": null, "passportUid": null}
  id: 502
  start: 2026-08-16T09:00:00Z
  duration: PT1H30M
  issue: {"id": null, "key": "TREK-1", "display": null}
  comment: Code review.
  ✓ Logged PT1H30M on TREK-1 (undoable)
```

`PT1H30M` is an **ISO 8601 duration**, which is what Tracker stores. Read it
left to right: `P` starts the period, `T` starts the time part, and each number
is followed by its unit.

| You want | Write |
|---|---|
| 30 minutes | `PT30M` |
| 1 hour | `PT1H` |
| 1 hour 30 minutes | `PT1H30M` |
| 2 days | `P2D` |
| 3 days and 4 hours | `P3DT4H` |

The `T` is not optional when there is a time part: `P1H` is not valid,
`PT1H` is. Note the `(undoable)` at the end of the output - `yandex session
undo` deletes this worklog again.

### Attach a file

To hang a file on the issue itself:

```bash
yandex tracker issue attachment-upload TREK-1 -f report.pdf
```

```
  Attachment on TREK-1
  ────────────────────
  createdAt: 2026-08-16T09:00:00Z
  createdBy: {"id": "j.doe", "display": "John Doe", "cloudUid": null, "passportUid": null}
  id: att-2
  name: report.pdf
  content: https://api.tracker.yandex.net/v3/attachments/att-2
  size: 13
  mimeType: application/octet-stream
  metadata: -
  ✓ Attached report.pdf to TREK-1
```

Attaching a file **to a comment** is two steps, because the file has to exist
before the comment can point at it. First upload it on its own:

```bash
yandex tracker attachment upload-temp -f report.pdf
```

```
  Temporary attachment
  ────────────────────
  createdAt: 2026-08-16T09:00:00Z
  createdBy: {"id": "j.doe", "display": "John Doe", "cloudUid": null, "passportUid": null}
  id: tmp-3
  name: report.pdf
  content: -
  size: 13
  mimeType: application/octet-stream
  metadata: -
  ✓ Uploaded report.pdf as tmp-3 (reference it with --attachment-id)
```

Then quote that `id` when you write the comment:

```bash
yandex tracker issue comment-add TREK-1 -t "Numbers are in the attached report." --attachment-id tmp-3
```

Tracker calls the first upload *temporary*, and the CLI says so when it prints
the id. Treat the two steps as one action and run the second straight away
rather than saving the id for later.

### Export a search to CSV

```bash
yandex export issues -q "Queue: TREK AND Updated: week()" -o report.csv --format csv
```

```
  Export
  ──────
  output: /Users/you/report.csv
  format: csv
  rows: 3
  columns: ["key", "summary", "status.display", "type.display", "priority.display", "assignee.display", "created_at", "updated_at"]
  file_size: 335
  ✓ Wrote 3 issue(s) to /Users/you/report.csv (335 bytes)
```

The file opens in Excel, Numbers or Google Sheets as it is:

```
key,summary,status.display,type.display,priority.display,assignee.display,created_at,updated_at
TREK-1,Design the CLI command tree,Открыт,Задача,Normal,John Doe,,
TREK-2,Implement the session store,Открыт,Задача,Normal,John Doe,,
TREK-3,Write the export pipeline,Открыт,Задача,Normal,John Doe,,
```

Those eight columns are the default. To choose your own, repeat `--column`
once per column. A column is a path into the issue: `key` is a plain field,
and `status.display` reaches into the `status` object for its human-readable
name - which is why the defaults are written that way.

```bash
yandex export issues -q "Queue: TREK" -o report.csv --format csv --column key --column summary --column assignee.display
```

Running the same export twice refuses rather than overwriting:

```
  ✗ report.csv already exists. Pass --overwrite to replace it.
```

Add `--overwrite` when replacing the file is what you meant - which it usually
is for a report you regenerate every Monday.

Besides `csv`, `--format json` writes the issues whole, with every field, for
another program to read, and `--format md` writes a Markdown table you can
paste into a wiki page or a comment.

### Create a Wiki page

```bash
yandex wiki page create --slug team/notes --title "Notes" --content @notes.md
```

```
  Wiki page created
  ─────────────────
  id: 11
  slug: team/notes
  title: Notes
  page_type: page
  attributes: {"created_at": "2026-08-16T09:00:00Z"}
  content: # Notes

Meeting notes for the week.

  ✓ Created wiki page team/notes
```

The `--slug` is the page's address inside the wiki - `team/notes` is what
appears at the end of its URL - and `--content @notes.md` reads the body out of
a file, which is far easier than quoting a whole page on one line.

Reading a page back gives you less than you might expect:

```bash
yandex wiki page get --slug team/notes
```

```
  Wiki page
  ─────────
  id: 11
  slug: team/notes
  title: Notes
  page_type: page
```

That is not a truncation. **A page read returns only `id`, `slug`, `title` and
`page_type`** unless you ask for more, because a wiki page can be very large
and most callers only want to identify it. `--content` adds the body:

```bash
yandex wiki page get --slug team/notes --content
```

`--fields` asks for anything else, comma separated - `content`, `attributes`,
`breadcrumbs`, `redirect`, `access_policy`, `access_lists`, `owner`:

```bash
yandex wiki page get --slug team/notes --fields content,attributes,access_lists
```

### Read a dynamic table

A dynamic table - a *grid* - lives on a page but is a separate object with its
own id. Find it by asking the page:

```bash
yandex wiki page grids 1
```

```
  Grids of page 1
  ───────────────
  ID  │ TITLE   │ CREATED
  ────────────────────────────────────
  g-1 │ Roadmap │ 2026-07-01T10:00:00Z
  1 row(s)
  next_cursor: None
```

`next_cursor` is `None` when that was the whole list; a page with many tables
hands back a cursor to pass to `--cursor` for the rest.

Then read it by that id:

```bash
yandex wiki grid get g-1
```

```
  Grid
  ────
  id: g-1
  title: Roadmap
  revision: 1
  rows: 1

  Columns
  ───────
  SLUG  │ TITLE │ TYPE   │ REQUIRED
  ─────────────────────────────────
  task  │ Task  │ string │ -
  owner │ Owner │ string │ -
  2 row(s)
```

Every write to a grid - `add-rows`, `update-cells`, `remove-columns` and the
rest - carries a `revision`, the number you can see above. It is how Wiki
notices that somebody edited the table between your reading it and your writing
to it. You do not have to track it: omit `--revision` and the CLI reads the
current one immediately before writing.

A row you add is a JSON **object**, not a list: each key is a column's `slug`
from the table above, and the ones you leave out stay empty.

```bash
yandex wiki grid add-rows g-1 --rows '[{"task": "Ship v1", "owner": "j.doe"}]'
```

## JSON output for scripts

Put `--json` before the domain and the command prints machine-readable JSON
instead of a table:

```bash
yandex --json tracker field resolutions
```

```
[
  {
    "id": 1,
    "key": "fixed",
    "version": 1,
    "name": "Решен",
    "order": 1
  },
  {
    "id": 2,
    "key": "wontFix",
    "version": 1,
    "name": "Не будет исправлено",
    "order": 2
  }
]
```

Three guarantees make this safe to parse:

- **Exactly one JSON document on stdout** - the stream another program reads
  when it runs `yandex`, as against stderr, where messages meant for a person
  go. Nothing else is printed on it: the progress lines, the `✓` confirmations
  and the decorated tables are all suppressed, so you never have to strip a
  banner off the front.
- **Failures are JSON too**, in the shape
  `{"error": {"type": ..., "message": ...}}`, with **exit code 1**. So you can
  parse stdout the same way whether the command worked or not:

  ```
  {
    "error": {
      "type": "BackendError",
      "message": "Issue 'NOPE-1' not found, or the token has no access to it."
    }
  }
  ```

- **`error.type` names the kind of failure**, so a script can branch on it
  without matching on English text. The ones you will meet are `ConfigError`,
  `BackendError`, `AccessDenied`, `ReadOnlyError`, `MissingArgument` and
  `ExportError`; [troubleshooting](troubleshooting.md) goes through each.

`jq` is the usual tool for picking things out of the result:

```bash
yandex --json tracker issue find -q "Queue: TREK" | jq -r '.[] | "\(.key)\t\(.summary)"'
```

```
TREK-1	Design the CLI command tree
TREK-2	Implement the session store
TREK-3	Write the export pipeline
```

## The full reference

Everything above is a selection. The complete list - every group, every
command, every option, with the exact text `--help` prints - is in
[`../reference.md`](../reference.md).

That page is generated from the program itself, so it cannot drift out of date
with the version you have installed. For the same reason it is **English
only**: the help text is printed by the CLI, and the CLI does not speak
Russian. The guides around it are translated; the reference is not.
